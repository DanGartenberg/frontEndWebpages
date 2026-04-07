# frozen_string_literal: true

# Sleep Animal Service V2
#
# Goals of this rewrite:
# 1. Expand into a complete 70-phenotype framework including a misc fallback.
# 2. Use sleep-pyramid-style axes plus nightly modifiers to score the best fit.
# 3. Preserve the currently implemented phenotype copy that already informed image creation.
# 4. Keep the service maintainable by separating metrics, modifiers, scoring, overrides,
#    and phenotype content.
#
# Assumptions:
# - `user` responds to sleep-facing associations / fields similarly to the prior draft:
#   - sleep_diaries
#   - sleep_schedule
#   - sleep_need
#   - sleep_goal_keys
#   - optional lifestyle flags such as `has_new_baby`, `caregiver_for_elder`,
#     `commute_minutes`, `travels_a_lot`, and `altitude_sleep_challenges`
# - Some survey flags will likely need to be mapped to real column names in your app.
#
# Suggested result-page fields:
# - key
# - animal_name
# - title
# - hook
# - description
# - why_you_got_this
# - ideal_next_step
# - cta_title
# - cta_body
# - primary_link
# - secondary_links
# - image
# - metrics
# - axis_profile
# - nightly_modifiers
# - heuristic_override
#
class SleepAnimalServiceV2
  attr_reader :user

  AXES = %i[
    duration_pressure
    continuity_disruption
    timing_misalignment
    physiologic_load
    hyperarousal
    daytime_restoration
  ].freeze

  PHENOTYPE_GROUPS = {
    insomnia_and_fragmentation: %i[
      cheetah_high_performance_insomniac firefly_sleep_onset_spinner mouse_anxious_sleeper
      rabbit_featherlight_sleeper frog_two_am_waker sparrow_too_early_riser
      cat_napper_rebounder weasel_fragmented_ruminator
    ],
    circadian_and_schedule: %i[
      owl_true_night_owl lark_morning_sprinter fox_irregular_schedule
      gazelle_jet_lag_hopper bat_shift_worker wolf_delayed_clock coyote_social_jetlagger
      eagle_advanced_clock mole_free_running_clock
    ],
    quantity_and_life_constraints: %i[
      horse_workhorse_restricted camel_sleep_debt_carrier kangaroo_new_parent
      goat_caregiver crow_long_commuter duck_sandwich_generation
      ant_overtime_grinder mule_heavy_load_sleeper
    ],
    airway_environment_and_physical: %i[
      bulldog_airway_clencher walrus_thunder_snorer porcupine_pain_tosser
      meerkat_noise_guard penguin_partner_poked lizard_heat_kicker
      armadillo_restless_legs whale_altitude_breather
    ],
    nonrestorative_and_optimization: %i[
      dolphin_half_awake hawk_precision_performer otter_balanced_builder
      koala_long_sleep_restorer elephant_short_sleep_ace bear_consistent_restorer
      dog_flexible_sleeper
    ],
    optimum_sleepers: %i[
      lion_deep_sleep_athlete raven_cognitive_marathoner panther_dream_weaver
      crane_zen_meditator stag_recovery_alchemist
    ],
    neuropsych_and_complex: %i[
      peacock_sleep_paralysis shark_half_alert platypus_dream_actor
      monkey_dream_intense turtle_slow_starter phoenix_rebound_sleeper
      bee_stress_sensitive ostrich_escape_sleeper
    ],
    special_overlap_profiles_a: %i[
      bison_apnea_insomnia crab_back_sleeper rhino_explosive_snorer
      alligator_bruxing_breather boar_alcohol_airway goose_self_snore_waker
      moose_positional_breather sea_lion_central_breather
    ],
    special_overlap_profiles_b: %i[
      seal_seasonal_adapter sloth_high_sleep_need jaguar_evening_performer
      hummingbird_micro_recovery raccoon_night_worker swallow_frequent_traveler
      vulture_grief_sleeper squirrel_stress_triggered
    ]
  }.freeze

  PRIMARY_LINK = "https://sleepspace.com/"
  SCIENCE_LINK = "https://sleepspace.com/science"
  COACHING_LINK = "https://sleepspace.com/sleep-coaching"
  CBTI_LINK = "https://sleepspace.com/cbt-i"

  def initialize(user:)
    @user = user
  end

  def self.catalog_overview
    PHENOTYPE_GROUPS.each_with_object({}) do |(group, keys), grouped|
      grouped[group] = keys.map do |key|
        phenotype = PHENOTYPES.fetch(key)
        {
          key: phenotype[:key],
          animal_name: phenotype[:animal_name],
          title: phenotype[:title],
          brief_description: phenotype[:hook]
        }
      end
    end.merge(
      general_foundation: [
        begin
          phenotype = PHENOTYPES.fetch(:chameleon_uncertain_mixer)
          {
            key: phenotype[:key],
            animal_name: phenotype[:animal_name],
            title: phenotype[:title],
            brief_description: phenotype[:hook]
          }
        end
      ]
    )
  end

  def call
    phenotype = resolve_phenotype

    {
      key: phenotype[:key],
      animal_name: phenotype[:animal_name],
      title: phenotype[:title],
      hook: phenotype[:hook],
      description: phenotype[:description],
      why_you_got_this: why_you_got_this(phenotype[:key]),
      ideal_next_step: phenotype[:ideal_next_step],
      cta_title: phenotype[:cta_title],
      cta_body: phenotype[:cta_body],
      primary_link: phenotype[:primary_link],
      secondary_links: phenotype[:secondary_links],
      image: phenotype[:image],
      metrics: summary_metrics,
      axis_profile: axis_profile,
      nightly_modifiers: nightly_modifiers,
      heuristic_override: heuristic_override_key,
      catalog_overview: self.class.catalog_overview
    }
  end

  private

  def resolve_phenotype
    return phenotype(:chameleon_uncertain_mixer) if insufficient_data?

    override = heuristic_override_key
    return phenotype(override) if override

    best_key, _score = candidate_scores.max_by { |key, score| [score, phenotype_priority(key)] }
    phenotype(best_key || :chameleon_uncertain_mixer)
  end

  def insufficient_data?
    last_diary.nil? && sleep_schedule.nil?
  end

  def candidate_scores
    @candidate_scores ||= begin
      scores = Hash.new(0)
      apply_axis_scoring(scores)
      apply_modifier_scoring(scores)
      apply_goal_scoring(scores)
      apply_baseline_scoring(scores)
      scores[:chameleon_uncertain_mixer] += 10
      scores
    end
  end

  def apply_axis_scoring(scores)
    add_score(scores, :horse_workhorse_restricted, axis_score(:duration_pressure) / 8.0)
    add_score(scores, :camel_sleep_debt_carrier, axis_score(:duration_pressure) / 7.0)
    add_score(scores, :crow_long_commuter, axis_score(:duration_pressure) / 16.0) if commute_pattern?
    add_score(scores, :ant_overtime_grinder, axis_score(:duration_pressure) / 10.0) if overtime_pattern?
    add_score(scores, :mule_heavy_load_sleeper, axis_score(:duration_pressure) / 11.0) if heavy_load_pattern?
    add_score(scores, :hummingbird_micro_recovery, axis_score(:duration_pressure) / 15.0) if fragmented_short_recovery_pattern?

    add_score(scores, :frog_two_am_waker, axis_score(:continuity_disruption) / 8.0)
    add_score(scores, :rabbit_featherlight_sleeper, axis_score(:continuity_disruption) / 9.0)
    add_score(scores, :weasel_fragmented_ruminator, axis_score(:continuity_disruption) / 10.0)
    add_score(scores, :meerkat_noise_guard, axis_score(:continuity_disruption) / 12.0) if environment_fragmented?
    add_score(scores, :penguin_partner_poked, axis_score(:continuity_disruption) / 13.0) if partner_disturbance?
    add_score(scores, :porcupine_pain_tosser, axis_score(:continuity_disruption) / 12.0) if pain_fragmented?
    add_score(scores, :armadillo_restless_legs, axis_score(:continuity_disruption) / 12.0) if restless_legs_pattern?

    add_score(scores, :owl_true_night_owl, axis_score(:timing_misalignment) / 9.0)
    add_score(scores, :fox_irregular_schedule, axis_score(:timing_misalignment) / 10.0)
    add_score(scores, :bat_shift_worker, axis_score(:timing_misalignment) / 9.0) if shift_work_pattern?
    add_score(scores, :gazelle_jet_lag_hopper, axis_score(:timing_misalignment) / 12.0) if travel_jet_lag_pattern?
    add_score(scores, :wolf_delayed_clock, axis_score(:timing_misalignment) / 12.0) if delayed_clock_pattern?
    add_score(scores, :coyote_social_jetlagger, axis_score(:timing_misalignment) / 10.0) if social_jetlag_delayed_pattern?
    add_score(scores, :eagle_advanced_clock, axis_score(:timing_misalignment) / 12.0) if advanced_clock_pattern?
    add_score(scores, :mole_free_running_clock, axis_score(:timing_misalignment) / 12.0) if free_running_pattern?
    add_score(scores, :raccoon_night_worker, axis_score(:timing_misalignment) / 13.0) if night_worker_pattern?
    add_score(scores, :swallow_frequent_traveler, axis_score(:timing_misalignment) / 14.0) if frequent_traveler_pattern?

    add_score(scores, :bulldog_airway_clencher, axis_score(:physiologic_load) / 8.0)
    add_score(scores, :walrus_thunder_snorer, axis_score(:physiologic_load) / 11.0)
    add_score(scores, :lizard_heat_kicker, axis_score(:physiologic_load) / 13.0) if waking_sweating?
    add_score(scores, :whale_altitude_breather, axis_score(:physiologic_load) / 14.0) if altitude_pattern?
    add_score(scores, :alligator_bruxing_breather, axis_score(:physiologic_load) / 15.0) if bruxism_pattern?
    add_score(scores, :goose_self_snore_waker, axis_score(:physiologic_load) / 15.0) if self_snore_waker_pattern?
    add_score(scores, :moose_positional_breather, axis_score(:physiologic_load) / 15.0) if positional_breather_pattern?
    add_score(scores, :sea_lion_central_breather, axis_score(:physiologic_load) / 15.0) if central_breathing_pattern?

    add_score(scores, :cheetah_high_performance_insomniac, axis_score(:hyperarousal) / 8.0)
    add_score(scores, :firefly_sleep_onset_spinner, axis_score(:hyperarousal) / 9.0)
    add_score(scores, :mouse_anxious_sleeper, axis_score(:hyperarousal) / 9.0)
    add_score(scores, :bee_stress_sensitive, axis_score(:hyperarousal) / 10.0)
    add_score(scores, :squirrel_stress_triggered, axis_score(:hyperarousal) / 11.0)
    add_score(scores, :vulture_grief_sleeper, axis_score(:hyperarousal) / 13.0) if grief_pattern?
    add_score(scores, :ostrich_escape_sleeper, axis_score(:hyperarousal) / 13.0) if avoidance_pattern?

    add_score(scores, :dolphin_half_awake, axis_score(:daytime_restoration) / 8.0)
    add_score(scores, :hawk_precision_performer, axis_score(:daytime_restoration) / 16.0) if athlete_or_performance_goal?
    add_score(scores, :otter_balanced_builder, axis_score(:daytime_restoration) / 16.0) if healthy_but_wants_optimization?
    add_score(scores, :koala_long_sleep_restorer, axis_score(:daytime_restoration) / 18.0) if long_sleep_need?
    add_score(scores, :sloth_high_sleep_need, axis_score(:daytime_restoration) / 18.0) if very_long_sleep_need?
    add_score(scores, :elephant_short_sleep_ace, axis_score(:daytime_restoration) / 20.0) if short_sleep_need_and_good_function?
    add_score(scores, :bear_consistent_restorer, axis_score(:daytime_restoration) / 22.0) if great_sleeper?
    add_score(scores, :dog_flexible_sleeper, axis_score(:daytime_restoration) / 22.0) if solid_flexible_sleeper?
    add_score(scores, :lion_deep_sleep_athlete, axis_score(:daytime_restoration) / 18.0) if physically_elite_recovery_pattern?
    add_score(scores, :raven_cognitive_marathoner, axis_score(:daytime_restoration) / 18.0) if mentally_elite_recovery_pattern?
    add_score(scores, :panther_dream_weaver, axis_score(:daytime_restoration) / 20.0) if dream_optimization_pattern?
    add_score(scores, :crane_zen_meditator, axis_score(:daytime_restoration) / 20.0) if meditative_sleep_mastery_pattern?
    add_score(scores, :stag_recovery_alchemist, axis_score(:daytime_restoration) / 18.0) if mind_body_optimizer_pattern?
  end

  def apply_modifier_scoring(scores)
    nightly_modifiers.each do |modifier|
      case modifier
      when :racing_mind
        add_score(scores, :cheetah_high_performance_insomniac, 16)
        add_score(scores, :mouse_anxious_sleeper, 14)
        add_score(scores, :weasel_fragmented_ruminator, 12)
      when :high_sleep_latency
        add_score(scores, :firefly_sleep_onset_spinner, 18)
        add_score(scores, :cheetah_high_performance_insomniac, 10)
      when :maintenance_waking
        add_score(scores, :frog_two_am_waker, 18)
        add_score(scores, :weasel_fragmented_ruminator, 8)
      when :early_waking
        add_score(scores, :sparrow_too_early_riser, 18)
        add_score(scores, :eagle_advanced_clock, 10)
      when :sleep_debt
        add_score(scores, :camel_sleep_debt_carrier, 16)
        add_score(scores, :cat_napper_rebounder, 10)
      when :restricted_opportunity
        add_score(scores, :horse_workhorse_restricted, 18)
        add_score(scores, :ant_overtime_grinder, 8)
      when :irregular_timing
        add_score(scores, :fox_irregular_schedule, 18)
        add_score(scores, :bat_shift_worker, 10)
        add_score(scores, :coyote_social_jetlagger, 14)
      when :late_clock
        add_score(scores, :owl_true_night_owl, 16)
        add_score(scores, :wolf_delayed_clock, 12)
        add_score(scores, :coyote_social_jetlagger, 16)
      when :social_jet_lag
        add_score(scores, :coyote_social_jetlagger, 20)
        add_score(scores, :wolf_delayed_clock, 8)
      when :early_clock
        add_score(scores, :lark_morning_sprinter, 16)
        add_score(scores, :eagle_advanced_clock, 12)
      when :snoring_or_airway
        add_score(scores, :bulldog_airway_clencher, 20)
        add_score(scores, :walrus_thunder_snorer, 12)
      when :pain_disruption
        add_score(scores, :porcupine_pain_tosser, 20)
      when :environmental_alerting
        add_score(scores, :meerkat_noise_guard, 18)
      when :partner_disturbance
        add_score(scores, :penguin_partner_poked, 18)
      when :thermal_discomfort
        add_score(scores, :lizard_heat_kicker, 18)
      when :nonrestorative
        add_score(scores, :dolphin_half_awake, 18)
      when :jet_lag
        add_score(scores, :gazelle_jet_lag_hopper, 18)
        add_score(scores, :swallow_frequent_traveler, 12)
      when :new_parent
        add_score(scores, :kangaroo_new_parent, 20)
      when :caregiver
        add_score(scores, :goat_caregiver, 20)
        add_score(scores, :duck_sandwich_generation, 10)
      when :commuter
        add_score(scores, :crow_long_commuter, 20)
      when :shift_work
        add_score(scores, :bat_shift_worker, 20)
        add_score(scores, :raccoon_night_worker, 10)
      when :performance_goal
        add_score(scores, :hawk_precision_performer, 18)
        add_score(scores, :jaguar_evening_performer, 10)
        add_score(scores, :lion_deep_sleep_athlete, 16)
        add_score(scores, :raven_cognitive_marathoner, 10)
      when :tracking_but_confused
        add_score(scores, :otter_balanced_builder, 16)
        add_score(scores, :stag_recovery_alchemist, 14)
      when :restless_legs
        add_score(scores, :armadillo_restless_legs, 18)
      when :vivid_dreams
        add_score(scores, :monkey_dream_intense, 18)
        add_score(scores, :platypus_dream_actor, 10)
        add_score(scores, :panther_dream_weaver, 16)
      when :dream_enactment
        add_score(scores, :platypus_dream_actor, 20)
      when :sleep_paralysis
        add_score(scores, :peacock_sleep_paralysis, 20)
      when :slow_start
        add_score(scores, :turtle_slow_starter, 18)
      when :seasonal_shift
        add_score(scores, :seal_seasonal_adapter, 20)
      when :micro_recovery
        add_score(scores, :hummingbird_micro_recovery, 18)
      when :rebound_pattern
        add_score(scores, :phoenix_rebound_sleeper, 18)
      when :stress_triggered
        add_score(scores, :squirrel_stress_triggered, 18)
        add_score(scores, :bee_stress_sensitive, 12)
      when :grief
        add_score(scores, :vulture_grief_sleeper, 22)
      end
    end
  end

  def apply_goal_scoring(scores)
    add_score(scores, :cheetah_high_performance_insomniac, 10) if racing_mind? && athlete_or_performance_goal?
    add_score(scores, :mouse_anxious_sleeper, 10) if racing_mind? && can_not_fall_asleep?
    add_score(scores, :frog_two_am_waker, 12) if cant_stay_asleep?
    add_score(scores, :sparrow_too_early_riser, 12) if waking_too_early?
    add_score(scores, :dolphin_half_awake, 12) if tired_throughout_day?
    add_score(scores, :otter_balanced_builder, 10) if tracks_but_confused?
    add_score(scores, :gazelle_jet_lag_hopper, 10) if travels_a_lot?
    add_score(scores, :hawk_precision_performer, 12) if high_performance_goal?
    add_score(scores, :coyote_social_jetlagger, 14) if social_jetlag_delayed_pattern?
    add_score(scores, :lion_deep_sleep_athlete, 14) if physically_elite_recovery_pattern?
    add_score(scores, :raven_cognitive_marathoner, 14) if mentally_elite_recovery_pattern?
    add_score(scores, :panther_dream_weaver, 14) if dream_optimization_pattern?
    add_score(scores, :crane_zen_meditator, 14) if meditative_sleep_mastery_pattern?
    add_score(scores, :stag_recovery_alchemist, 14) if mind_body_optimizer_pattern?
  end

  def apply_baseline_scoring(scores)
    add_score(scores, :bear_consistent_restorer, 25) if great_sleeper?
    add_score(scores, :dog_flexible_sleeper, 20) if solid_flexible_sleeper?
    add_score(scores, :koala_long_sleep_restorer, 18) if long_sleep_need?
    add_score(scores, :sloth_high_sleep_need, 24) if very_long_sleep_need?
    add_score(scores, :elephant_short_sleep_ace, 24) if short_sleep_need_and_good_function?
    add_score(scores, :lion_deep_sleep_athlete, 26) if physically_elite_recovery_pattern?
    add_score(scores, :raven_cognitive_marathoner, 26) if mentally_elite_recovery_pattern?
    add_score(scores, :panther_dream_weaver, 24) if dream_optimization_pattern?
    add_score(scores, :crane_zen_meditator, 24) if meditative_sleep_mastery_pattern?
    add_score(scores, :stag_recovery_alchemist, 24) if mind_body_optimizer_pattern?
    add_score(scores, :chameleon_uncertain_mixer, 20) if nightly_modifiers.empty?
  end

  def add_score(scores, key, amount)
    scores[key] += amount.to_i
  end

  def heuristic_override_key
    return :bison_apnea_insomnia if severe_airway_risk? && sleep_latency_high?
    return :crab_back_sleeper if back_sleeping_pattern?
    return :rhino_explosive_snorer if explosive_snoring_pattern?
    return :alligator_bruxing_breather if bruxism_pattern? && snoring_or_grinding_or_breathing?
    return :boar_alcohol_airway if alcohol_airway_pattern?
    return :goose_self_snore_waker if self_snore_waker_pattern?
    return :moose_positional_breather if positional_breather_pattern?
    return :sea_lion_central_breather if central_breathing_pattern?
    return :shark_half_alert if severe_airway_risk? && environment_fragmented?
    return :weasel_fragmented_ruminator if racing_mind? && maintenance_pattern?
    return :coyote_social_jetlagger if social_jetlag_delayed_pattern?
    return :wolf_delayed_clock if delayed_clock_pattern? && sleep_latency_high?
    return :eagle_advanced_clock if advanced_clock_pattern? && early_waking_pattern?
    return :mole_free_running_clock if free_running_pattern?
    return :duck_sandwich_generation if sandwich_generation_pattern?
    return :ant_overtime_grinder if overtime_pattern?
    return :mule_heavy_load_sleeper if heavy_load_pattern?
    return :armadillo_restless_legs if restless_legs_pattern?
    return :whale_altitude_breather if altitude_pattern?
    return :peacock_sleep_paralysis if sleep_paralysis_pattern?
    return :platypus_dream_actor if dream_enactment_pattern?
    return :monkey_dream_intense if vivid_dream_pattern?
    return :turtle_slow_starter if slow_starter_pattern?
    return :phoenix_rebound_sleeper if rebound_recovery_pattern?
    return :bee_stress_sensitive if stress_sensitive_pattern?
    return :ostrich_escape_sleeper if avoidance_pattern?
    return :seal_seasonal_adapter if seasonal_shift_pattern?
    return :sloth_high_sleep_need if very_long_sleep_need?
    return :jaguar_evening_performer if evening_performer_pattern?
    return :hummingbird_micro_recovery if fragmented_short_recovery_pattern?
    return :raccoon_night_worker if night_worker_pattern?
    return :swallow_frequent_traveler if frequent_traveler_pattern?
    return :vulture_grief_sleeper if grief_pattern?
    return :squirrel_stress_triggered if stress_triggered_pattern?

    nil
  end

  def phenotype_priority(key)
    return 999 if key == heuristic_override_key
    return 500 if PHENOTYPE_GROUPS.values.flatten.include?(key)

    0
  end

  # ============================================================
  # Metrics
  # ============================================================

  def last_diary
    @last_diary ||= user.respond_to?(:sleep_diaries) ? user.sleep_diaries&.last : nil
  end

  def sleep_schedule
    @sleep_schedule ||= user.respond_to?(:sleep_schedule) ? user.sleep_schedule : nil
  end

  def sleep_efficiency
    @sleep_efficiency ||= numeric_value(last_diary, :sleep_efficiency)
  end

  def sleep_quality
    @sleep_quality ||= numeric_value(last_diary, :quality_of_sleep_rating)
  end

  def total_sleep_hours
    minutes = numeric_value(last_diary, :total_sleep_time)
    minutes ? (minutes / 60.0) : 0.0
  end

  def sleep_need_hours
    minutes = user.respond_to?(:sleep_need) ? user.sleep_need.to_f : 0.0
    minutes.positive? ? minutes / 60.0 : 0.0
  end

  def sleep_debt_hours
    [sleep_need_hours - total_sleep_hours, 0].max
  end

  def sleep_latency_minutes
    integer_value(last_diary, :sleep_latency)
  end

  def awakenings_count
    integer_value(last_diary, :number_of_awakenings)
  end

  def waso_minutes
    integer_value(last_diary, :wake_after_sleep_onset)
  end

  def bedtime_hour
    numeric_value(sleep_schedule, :average_bedtime_in_hours)
  end

  def wake_hour
    numeric_value(sleep_schedule, :average_waketime_in_hours)
  end

  def schedule_variability
    numeric_value(sleep_schedule, :bedtime_variability_hours)
  end

  def work_duration_hours
    numeric_value(sleep_schedule, :work_duration) || 0.0
  end

  def numeric_value(object, method_name)
    return nil unless object&.respond_to?(method_name)

    object.public_send(method_name).to_f
  end

  def integer_value(object, method_name)
    return 0 unless object&.respond_to?(method_name)

    object.public_send(method_name).to_i
  end

  # ============================================================
  # Survey helpers
  # ============================================================

  def goal_selected?(key)
    return false unless user.respond_to?(:sleep_goal_keys)

    Array(user.sleep_goal_keys).map(&:to_s).include?(key.to_s)
  end

  def can_not_fall_asleep?
    goal_selected?(:cant_fall_asleep)
  end

  def cant_stay_asleep?
    goal_selected?(:cant_stay_asleep)
  end

  def waking_too_early?
    goal_selected?(:waking_too_early)
  end

  def pain_bothering_sleep?
    goal_selected?(:pain_bothering_sleep)
  end

  def sounds_or_light_waking?
    goal_selected?(:sounds_or_light_waking_you_up)
  end

  def partner_or_pet_waking?
    goal_selected?(:partner_or_pet_waking_you_up)
  end

  def waking_up_sweating?
    goal_selected?(:waking_up_sweating)
  end

  def tired_throughout_day?
    goal_selected?(:still_tired_throughout_day)
  end

  def not_enough_time_to_sleep?
    goal_selected?(:not_enough_time_to_sleep)
  end

  def snoring_or_grinding_or_breathing?
    goal_selected?(:snore_loudly_grind_teeth_or_out_of_breath)
  end

  def mind_races?
    goal_selected?(:mind_races_when_trying_to_sleep)
  end

  def shift_worker_or_irregular?
    goal_selected?(:shift_worker_or_irregular_schedule)
  end

  def high_performance_goal?
    goal_selected?(:high_performance_athlete_or_effectiveness)
  end

  def tracks_but_confused?
    goal_selected?(:uses_technology_to_track_sleep)
  end

  def travels_a_lot?
    goal_selected?(:travel_a_lot_and_suffer_from_jet_lag) ||
      (user.respond_to?(:travels_a_lot) && user.travels_a_lot)
  end

  def grief_flag?
    goal_selected?(:grief_affecting_sleep) || truthy_flag?(:grief_affecting_sleep)
  end

  def stress_triggered_flag?
    goal_selected?(:stress_affecting_sleep) || truthy_flag?(:stress_affecting_sleep)
  end

  def truthy_flag?(method_name)
    user.respond_to?(method_name) && !!user.public_send(method_name)
  end

  # ============================================================
  # Sleep-pyramid axes
  # ============================================================

  def axis_profile
    @axis_profile ||= AXES.each_with_object({}) do |axis, hash|
      hash[axis] = axis_score(axis)
    end
  end

  def axis_score(axis)
    case axis
    when :duration_pressure
      [
        (sleep_debt_hours * 30),
        (not_enough_time_to_sleep? ? 18 : 0),
        (work_duration_hours >= 10 ? 12 : 0),
        (commute_pattern? ? 10 : 0)
      ].sum.clamp(0, 100)
    when :continuity_disruption
      [
        (awakenings_count * 12),
        (waso_minutes / 3.0),
        (sleep_efficiency && sleep_efficiency < 90 ? (90 - sleep_efficiency) * 2 : 0),
        (partner_disturbance? ? 10 : 0),
        (environment_fragmented? ? 10 : 0),
        (pain_fragmented? ? 12 : 0)
      ].sum.clamp(0, 100)
    when :timing_misalignment
      [
        (schedule_variability.to_f * 18),
        (true_night_owl? ? 20 : 0),
        (true_morning_lark? ? 12 : 0),
        (shift_work_pattern? ? 24 : 0),
        (travel_jet_lag_pattern? ? 24 : 0)
      ].sum.clamp(0, 100)
    when :physiologic_load
      [
        (severe_airway_risk? ? 35 : 0),
        (snoring_without_clear_severity? ? 18 : 0),
        (pain_fragmented? ? 14 : 0),
        (waking_sweating? ? 10 : 0),
        (restless_legs_pattern? ? 18 : 0),
        (altitude_pattern? ? 14 : 0)
      ].sum.clamp(0, 100)
    when :hyperarousal
      [
        (racing_mind? ? 26 : 0),
        (sleep_latency_high? ? 22 : 0),
        (stress_sensitive_pattern? ? 18 : 0),
        (grief_pattern? ? 20 : 0),
        (avoidance_pattern? ? 10 : 0)
      ].sum.clamp(0, 100)
    when :daytime_restoration
      [
        (tired_throughout_day? ? 28 : 0),
        (nonrestorative_sleep? ? 24 : 0),
        (sleep_quality && sleep_quality > 0 ? (10 - sleep_quality) * 6 : 0),
        (sleep_debt_hours * 8)
      ].sum.clamp(0, 100)
    else
      0
    end
  end

  def nightly_modifiers
    @nightly_modifiers ||= begin
      [].tap do |mods|
        mods << :racing_mind if racing_mind?
        mods << :high_sleep_latency if sleep_latency_high?
        mods << :maintenance_waking if maintenance_pattern?
        mods << :early_waking if early_waking_pattern?
        mods << :sleep_debt if chronic_sleep_debt?
        mods << :restricted_opportunity if work_restricted?
        mods << :irregular_timing if irregular_schedule_pattern?
        mods << :late_clock if true_night_owl?
        mods << :social_jet_lag if social_jetlag_delayed_pattern?
        mods << :early_clock if true_morning_lark?
        mods << :snoring_or_airway if snoring_or_grinding_or_breathing?
        mods << :pain_disruption if pain_fragmented?
        mods << :environmental_alerting if environment_fragmented?
        mods << :partner_disturbance if partner_disturbance?
        mods << :thermal_discomfort if waking_sweating?
        mods << :nonrestorative if nonrestorative_sleep?
        mods << :jet_lag if travel_jet_lag_pattern?
        mods << :new_parent if new_parent_pattern?
        mods << :caregiver if caregiver_pattern?
        mods << :commuter if commute_pattern?
        mods << :shift_work if shift_work_pattern?
        mods << :performance_goal if athlete_or_performance_goal?
        mods << :tracking_but_confused if tracks_but_confused?
        mods << :restless_legs if restless_legs_pattern?
        mods << :vivid_dreams if vivid_dream_pattern?
        mods << :dream_enactment if dream_enactment_pattern?
        mods << :sleep_paralysis if sleep_paralysis_pattern?
        mods << :slow_start if slow_starter_pattern?
        mods << :seasonal_shift if seasonal_shift_pattern?
        mods << :micro_recovery if fragmented_short_recovery_pattern?
        mods << :rebound_pattern if rebound_recovery_pattern?
        mods << :stress_triggered if stress_triggered_pattern?
        mods << :grief if grief_pattern?
      end
    end
  end

  # ============================================================
  # Pattern helpers
  # ============================================================

  def severe_airway_risk?
    snoring_or_grinding_or_breathing? && tired_throughout_day? && sleep_efficiency.to_f.positive? && sleep_efficiency < 85
  end

  def snoring_without_clear_severity?
    snoring_or_grinding_or_breathing?
  end

  def pain_fragmented?
    pain_bothering_sleep? || (pain_bothering_sleep? && awakenings_count >= 3 && waso_minutes >= 30)
  end

  def environment_fragmented?
    sounds_or_light_waking? && (awakenings_count >= 2 || sleep_efficiency.to_f < 85)
  end

  def partner_disturbance?
    partner_or_pet_waking?
  end

  def waking_sweating?
    waking_up_sweating?
  end

  def racing_mind?
    mind_races?
  end

  def sleep_latency_high?
    can_not_fall_asleep? || sleep_latency_minutes >= 30
  end

  def maintenance_pattern?
    cant_stay_asleep? || awakenings_count >= 3 || waso_minutes >= 45
  end

  def early_waking_pattern?
    waking_too_early? || (wake_hour && wake_hour < 5.5)
  end

  def light_fragmented_sleep?
    sleep_efficiency.to_f.positive? && sleep_efficiency < 85 && awakenings_count >= 2
  end

  def nap_heavy_recovery_pattern?
    sleep_debt_hours >= 1.5 && sleep_latency_minutes < 10
  end

  def work_restricted?
    not_enough_time_to_sleep? || work_duration_hours >= 10 || sleep_debt_hours >= 1.0
  end

  def new_parent_pattern?
    truthy_flag?(:has_new_baby)
  end

  def caregiver_pattern?
    truthy_flag?(:caregiver_for_elder)
  end

  def commute_pattern?
    user.respond_to?(:commute_minutes) && user.commute_minutes.to_i >= 90
  end

  def chronic_sleep_debt?
    sleep_debt_hours >= 2.0
  end

  def true_night_owl?
    !shift_worker_or_irregular? &&
      ((sleep_schedule&.respond_to?(:night_owl?) && sleep_schedule.night_owl?) ||
      delayed_clock_pattern?)
  end

  def true_morning_lark?
    (sleep_schedule&.respond_to?(:morning_lark?) && sleep_schedule.morning_lark?) ||
      advanced_clock_pattern?
  end

  def travel_jet_lag_pattern?
    travels_a_lot?
  end

  def social_jet_lag_goal?
    goal_selected?(:social_jet_lag) ||
      goal_selected?(:delayed_sleep_phase_syndrome) ||
      goal_selected?(:delayed_sleep_phase) ||
      goal_selected?(:goes_out_late_on_weekends) ||
      truthy_flag?(:social_jet_lag) ||
      truthy_flag?(:delayed_sleep_phase_syndrome)
  end

  def irregular_schedule_pattern?
    shift_worker_or_irregular? || schedule_variability.to_f >= 2.0
  end

  def weekend_late_social_pattern?
    goal_selected?(:goes_out_late_on_weekends) ||
      goal_selected?(:weekend_late_nights) ||
      truthy_flag?(:late_weekend_social_schedule) ||
      truthy_flag?(:weekend_social_nights)
  end

  def early_weekday_wake_requirement?
    (wake_hour && wake_hour < 7.0) ||
      truthy_flag?(:early_weekday_schedule) ||
      truthy_flag?(:early_school_or_work_start)
  end

  def shift_work_pattern?
    shift_worker_or_irregular? && work_duration_hours.positive?
  end

  def nonrestorative_sleep?
    tired_throughout_day? && total_sleep_hours >= 7.0 && sleep_quality.to_f.positive? && sleep_quality <= 5
  end

  def long_sleep_need?
    sleep_need_hours >= 9.0
  end

  def very_long_sleep_need?
    sleep_need_hours >= 10.0
  end

  def short_sleep_need_and_good_function?
    sleep_need_hours.positive? && sleep_need_hours <= 6.5 &&
      sleep_quality.to_f >= 7 && sleep_efficiency.to_f >= 85
  end

  def athlete_or_performance_goal?
    high_performance_goal?
  end

  def healthy_but_wants_optimization?
    tracks_but_confused? && sleep_efficiency.to_f >= 85 && sleep_quality.to_f >= 6
  end

  def great_sleeper?
    sleep_efficiency.to_f.between?(85, 95) &&
      total_sleep_hours.between?(7.0, 9.0) &&
      sleep_quality.to_f >= 7 &&
      sleep_debt_hours < 0.75
  end

  def elite_consistent_sleeper?
    sleep_efficiency.to_f >= 90 &&
      total_sleep_hours.between?(7.25, 8.75) &&
      sleep_quality.to_f >= 8 &&
      schedule_variability.to_f < 1.0
  end

  def meditation_or_mindfulness_goal?
    goal_selected?(:meditation_for_sleep) ||
      goal_selected?(:mindfulness_for_sleep) ||
      goal_selected?(:yoga_nidra) ||
      truthy_flag?(:meditates_regularly) ||
      truthy_flag?(:mindfulness_practice) ||
      truthy_flag?(:yoga_nidra_practice)
  end

  def mental_performance_goal?
    goal_selected?(:mental_performance_and_focus) ||
      goal_selected?(:cognitive_performance) ||
      truthy_flag?(:high_cognitive_load) ||
      truthy_flag?(:knowledge_worker_sleep_focus)
  end

  def dream_optimization_goal?
    goal_selected?(:lucid_dreaming) ||
      goal_selected?(:dream_optimization) ||
      goal_selected?(:dream_recall) ||
      truthy_flag?(:lucid_dream_practice) ||
      truthy_flag?(:dream_journaling)
  end

  def physically_elite_recovery_pattern?
    elite_consistent_sleeper? && athlete_or_performance_goal? && total_sleep_hours >= 7.0
  end

  def mentally_elite_recovery_pattern?
    elite_consistent_sleeper? && (mental_performance_goal? || (athlete_or_performance_goal? && tracks_but_confused?))
  end

  def dream_optimization_pattern?
    elite_consistent_sleeper? &&
      vivid_dream_pattern? &&
      !dream_enactment_pattern? &&
      (dream_optimization_goal? || sleep_quality.to_f >= 8)
  end

  def meditative_sleep_mastery_pattern?
    elite_consistent_sleeper? &&
      meditation_or_mindfulness_goal? &&
      !racing_mind? &&
      awakenings_count <= 1
  end

  def mind_body_optimizer_pattern?
    elite_consistent_sleeper? &&
      tracks_but_confused? &&
      (meditation_or_mindfulness_goal? || athlete_or_performance_goal? || mental_performance_goal?)
  end

  def solid_flexible_sleeper?
    sleep_efficiency.to_f >= 85 && sleep_quality.to_f >= 6
  end

  def delayed_clock_pattern?
    bedtime_hour && bedtime_hour >= 24.0
  end

  def social_jetlag_delayed_pattern?
    delayed_clock_pattern? &&
      sleep_latency_high? &&
      early_weekday_wake_requirement? &&
      (social_jet_lag_goal? || weekend_late_social_pattern? || schedule_variability.to_f >= 2.5)
  end

  def advanced_clock_pattern?
    bedtime_hour && bedtime_hour <= 21.0
  end

  def free_running_pattern?
    truthy_flag?(:free_running_sleep_schedule) || schedule_variability.to_f >= 3.5
  end

  def overtime_pattern?
    work_duration_hours >= 11 || truthy_flag?(:working_multiple_jobs)
  end

  def heavy_load_pattern?
    truthy_flag?(:high_daily_care_load) || (caregiver_pattern? && work_duration_hours >= 8)
  end

  def restless_legs_pattern?
    goal_selected?(:restless_legs) || truthy_flag?(:restless_legs_symptoms)
  end

  def altitude_pattern?
    goal_selected?(:altitude_or_thin_air_sleep) || truthy_flag?(:altitude_sleep_challenges)
  end

  def bruxism_pattern?
    goal_selected?(:teeth_grinding) || truthy_flag?(:teeth_grinding_at_night)
  end

  def self_snore_waker_pattern?
    goal_selected?(:wake_self_snoring) || truthy_flag?(:wake_self_snoring)
  end

  def positional_breather_pattern?
    goal_selected?(:worse_sleep_on_back) || truthy_flag?(:worse_sleep_on_back)
  end

  def back_sleeping_pattern?
    positional_breather_pattern?
  end

  def central_breathing_pattern?
    goal_selected?(:central_sleep_apnea_history) || truthy_flag?(:central_sleep_apnea_history)
  end

  def explosive_snoring_pattern?
    severe_airway_risk? && goal_selected?(:loud_snoring)
  end

  def alcohol_airway_pattern?
    goal_selected?(:alcohol_affects_sleep) || truthy_flag?(:alcohol_affects_sleep)
  end

  def sandwich_generation_pattern?
    caregiver_pattern? && truthy_flag?(:has_children_at_home)
  end

  def sleep_paralysis_pattern?
    goal_selected?(:sleep_paralysis) || truthy_flag?(:sleep_paralysis_history)
  end

  def dream_enactment_pattern?
    goal_selected?(:act_out_dreams) || truthy_flag?(:dream_enactment)
  end

  def vivid_dream_pattern?
    goal_selected?(:vivid_dreams) || truthy_flag?(:vivid_dreams)
  end

  def slow_starter_pattern?
    goal_selected?(:hard_to_wake_up) || truthy_flag?(:sleep_inertia)
  end

  def rebound_recovery_pattern?
    sleep_debt_hours >= 2.5 && nap_heavy_recovery_pattern?
  end

  def stress_sensitive_pattern?
    racing_mind? && stress_triggered_flag?
  end

  def avoidance_pattern?
    goal_selected?(:avoid_bed_because_of_sleep_stress) || truthy_flag?(:avoid_bed_because_of_sleep_stress)
  end

  def seasonal_shift_pattern?
    goal_selected?(:seasonal_sleep_changes) || truthy_flag?(:seasonal_sleep_changes)
  end

  def evening_performer_pattern?
    athlete_or_performance_goal? && true_night_owl?
  end

  def fragmented_short_recovery_pattern?
    sleep_debt_hours >= 1.0 && total_sleep_hours < 6.5 && awakenings_count >= 2
  end

  def night_worker_pattern?
    shift_work_pattern? && bedtime_hour && bedtime_hour >= 6.0
  end

  def frequent_traveler_pattern?
    travel_jet_lag_pattern? && truthy_flag?(:frequent_business_travel)
  end

  def grief_pattern?
    grief_flag?
  end

  def stress_triggered_pattern?
    stress_triggered_flag?
  end

  # ============================================================
  # Explainability
  # ============================================================

  def why_you_got_this(key)
    case key
    when :cheetah_high_performance_insomniac
      [
        "You reported a racing mind around sleep.",
        ("Your sleep latency was #{sleep_latency_minutes} minutes." if sleep_latency_minutes.positive?),
        ("Your sleep efficiency was #{sleep_efficiency.round}%." if sleep_efficiency.to_f.positive?)
      ].compact
    when :firefly_sleep_onset_spinner
      [
        "Your main signal points to difficulty falling asleep.",
        ("Your sleep latency was #{sleep_latency_minutes} minutes." if sleep_latency_minutes.positive?)
      ].compact
    when :frog_two_am_waker
      [
        "Your pattern points to waking during the night.",
        ("You recorded #{awakenings_count} awakenings." if awakenings_count.positive?),
        ("You were awake for about #{waso_minutes} minutes after first falling asleep." if waso_minutes.positive?)
      ].compact
    when :sparrow_too_early_riser
      ["Your answers suggest early-morning waking is a key issue."]
    when :bulldog_airway_clencher
      [
        "You reported snoring, grinding, or breathing-related sleep concerns.",
        "Your daytime fatigue suggests sleep quality may be getting disrupted overnight."
      ]
    when :dolphin_half_awake
      [
        "You appear to be getting enough total sleep, but not waking up refreshed.",
        ("Your total sleep time was #{total_sleep_hours.round(1)} hours." if total_sleep_hours.positive?),
        ("Your self-rated sleep quality was #{sleep_quality.round}/10." if sleep_quality.to_f.positive?)
      ].compact
    when :horse_workhorse_restricted
      [
        "Your pattern suggests insufficient time or opportunity for sleep.",
        ("Estimated sleep debt: #{sleep_debt_hours.round(1)} hours." if sleep_debt_hours.positive?)
      ].compact
    when :owl_true_night_owl
      ["Your sleep timing suggests a naturally later body clock."]
    when :coyote_social_jetlagger
      [
        "Your pattern looks like late-weekend timing colliding with early weekday obligations.",
        ("Your schedule variability was #{schedule_variability.round(1)} hours." if schedule_variability.to_f.positive?),
        ("Your sleep latency was #{sleep_latency_minutes} minutes." if sleep_latency_minutes.positive?)
      ].compact
    when :lark_morning_sprinter
      ["Your sleep timing suggests an earlier natural rhythm."]
    when :koala_long_sleep_restorer, :sloth_high_sleep_need
      ["Your reported sleep need is longer than average."]
    when :lion_deep_sleep_athlete
      [
        "Your pattern looks highly restorative and performance-oriented.",
        ("Your sleep efficiency was #{sleep_efficiency.round}%." if sleep_efficiency.to_f.positive?),
        ("Your self-rated sleep quality was #{sleep_quality.round}/10." if sleep_quality.to_f.positive?)
      ].compact
    when :raven_cognitive_marathoner
      [
        "Your sleep data suggests strong recovery paired with heavy mental output.",
        ("Your total sleep time was #{total_sleep_hours.round(1)} hours." if total_sleep_hours.positive?),
        ("Your sleep quality was #{sleep_quality.round}/10." if sleep_quality.to_f.positive?)
      ].compact
    when :panther_dream_weaver
      [
        "Your sleep appears restorative, and your answers suggest dreams are part of how you optimize recovery.",
        ("Your sleep efficiency was #{sleep_efficiency.round}%." if sleep_efficiency.to_f.positive?)
      ].compact
    when :crane_zen_meditator
      [
        "Your profile points to calm, consistent sleep supported by meditation or mindfulness practices.",
        ("You recorded #{awakenings_count} awakenings." if awakenings_count.positive?)
      ].compact
    when :stag_recovery_alchemist
      [
        "Your pattern suggests you actively refine sleep as a mind-body recovery tool.",
        ("Your schedule variability was #{schedule_variability.round(1)} hours." if schedule_variability.to_f.positive?)
      ].compact
    when :bison_apnea_insomnia
      [
        "Your data shows a mix of airway strain and trouble initiating sleep.",
        ("Your sleep latency was #{sleep_latency_minutes} minutes." if sleep_latency_minutes.positive?),
        ("Your sleep efficiency was #{sleep_efficiency.round}%." if sleep_efficiency.to_f.positive?)
      ].compact
    when :chameleon_uncertain_mixer
      ["Your current signals are mixed, flexible, or still emerging, so a more specific phenotype has not clearly separated itself yet."]
    else
      ["Your recent survey, sleep diary, modifiers, and sleep-pyramid axis signals suggest this is the closest overall fit right now."]
    end
  end

  def summary_metrics
    {
      ideal_bedtime: ideal_bedtime_string,
      efficiency: sleep_efficiency.to_f.round,
      sleep_quality: sleep_quality.to_f.round,
      total_sleep_hours: total_sleep_hours.round(1),
      sleep_need_hours: sleep_need_hours.round(1),
      sleep_debt_hours: sleep_debt_hours.round(1),
      latency_minutes: sleep_latency_minutes,
      awakenings: awakenings_count,
      waso_minutes: waso_minutes,
      schedule_variability_hours: schedule_variability.to_f.round(1)
    }
  end

  def ideal_bedtime_string
    return nil unless sleep_schedule&.respond_to?(:average_bedtime_string)

    sleep_schedule.average_bedtime_string
  end

  def phenotype(key)
    PHENOTYPES.fetch(key)
  end

  def self.phenotype_data(
    key:,
    animal_name:,
    title:,
    hook:,
    description:,
    ideal_next_step:,
    cta_title:,
    cta_body:,
    image:,
    primary_link: PRIMARY_LINK,
    secondary_links: []
  )
    {
      key: key,
      animal_name: animal_name,
      title: title,
      hook: hook,
      description: description,
      ideal_next_step: ideal_next_step,
      cta_title: cta_title,
      cta_body: cta_body,
      primary_link: primary_link,
      secondary_links: secondary_links,
      image: image
    }
  end

  PHENOTYPES = {
    cheetah_high_performance_insomniac: phenotype_data(
      key: :cheetah_high_performance_insomniac,
      animal_name: "Cheetah",
      title: "High-Performance Insomniac",
      hook: "Your brain runs at full speed, even when your body is ready for bed.",
      description: "You tend to carry momentum into the night. Racing thoughts, pressure to perform, and difficulty disengaging can delay sleep even when you are clearly tired. This pattern often looks productive on the outside, but over time it can chip away at recovery, mood, and consistency. The good news is that this is highly trainable when you pair the right bedtime wind-down with a sleep schedule your nervous system can trust. People in this phenotype often need permission to stop striving before they can start sleeping.",
      ideal_next_step: "Start with a 20-minute decompression ritual and a consistent sleep window. Inside SleepSpace, begin with guided wind-down audio, thought-unloading, and a simple schedule target that helps your brain stop performing and start sleeping.",
      cta_title: "Turn off performance mode at night",
      cta_body: "Use SleepSpace to build a repeatable wind-down routine, calm your mind faster, and train your body to fall asleep without fighting it.",
      image: "animal-cheetah.png",
      secondary_links: [SCIENCE_LINK]
    ),
    firefly_sleep_onset_spinner: phenotype_data(
      key: :firefly_sleep_onset_spinner,
      animal_name: "Firefly",
      title: "Sleep-Onset Spinner",
      hook: "You feel tired, but your system does not flip fully into sleep mode.",
      description: "Your main challenge is getting to sleep in the first place. Once your head hits the pillow, you may start thinking, planning, reviewing, or simply waiting for sleep to happen. That waiting can become part of the problem and make bedtime feel effortful. A gentler, more repeatable pre-sleep rhythm usually works better than trying harder. The less sleep feels like a performance test, the more likely your system is to finally let go.",
      ideal_next_step: "Focus first on reducing sleep latency, not fixing everything at once. SleepSpace can guide you through calming audio, structured bedtime timing, and behavioral tools that make sleep feel automatic again.",
      cta_title: "Fall asleep with less effort",
      cta_body: "Build a smoother path into sleep with guided relaxation, bedtime consistency, and personalized coaching inside SleepSpace.",
      image: "animal-firefly.png"
    ),
    mouse_anxious_sleeper: phenotype_data(
      key: :mouse_anxious_sleeper,
      animal_name: "Mouse",
      title: "Anxious Sleeper",
      hook: "Your mind gets louder when the room gets quiet.",
      description: "Worry tends to arrive right when you are trying to let go. You may replay conversations, think through tomorrow, or scan for what could go wrong. Sleep becomes lighter and more fragile when your nervous system stays in problem-solving mode. This type of sleep usually improves when the body feels safer and the mind has a place to put unfinished thoughts. For many people here, the real shift happens when nighttime stops being the only time the mind tries to process the day.",
      ideal_next_step: "Try a structured mental off-ramp before bed. SleepSpace can help with guided breathing, sleep meditations, and routines that lower nighttime hyperarousal.",
      cta_title: "Quiet the mind that keeps reloading",
      cta_body: "Use SleepSpace to shift out of worry mode with guided calm-down exercises designed specifically for bedtime.",
      image: "animal-mouse.png",
      secondary_links: [CBTI_LINK]
    ),
    rabbit_featherlight_sleeper: phenotype_data(
      key: :rabbit_featherlight_sleeper,
      animal_name: "Rabbit",
      title: "Featherlight Sleeper",
      hook: "Sleep comes, but it stays close to the surface.",
      description: "You may drift off, but your sleep is light, sensitive, and easy to interrupt. Noise, stress, temperature, or even anticipation can keep your system half-alert. This often leads to long nights that technically contain sleep but do not feel deeply restorative. Strengthening sleep continuity usually matters more for you than simply increasing time in bed. Your sleep tends to improve when the night feels more protected, buffered, and predictable from start to finish.",
      ideal_next_step: "Improve the depth and continuity of your sleep environment. SleepSpace can help by layering sound, schedule guidance, and bedtime routines that reduce nighttime reactivity.",
      cta_title: "Make sleep feel deeper, not just longer",
      cta_body: "Create a more protected sleep window with personalized soundscapes and behavior change tools in SleepSpace.",
      image: "animal-rabbit.png"
    ),
    frog_two_am_waker: phenotype_data(
      key: :frog_two_am_waker,
      animal_name: "Frog",
      title: "2 AM Waker",
      hook: "Falling asleep may not be the problem. Staying asleep is.",
      description: "Your nights tend to break in the middle. You may wake for stretches, feel alert too early, or find yourself stuck awake after a brief interruption. That pattern can quietly drain recovery even if bedtime looks decent on paper. Your best path forward is usually about reducing awakenings and making it easier to settle back down. What matters most is teaching the night to feel continuous again instead of something you have to restart over and over.",
      ideal_next_step: "Train your nights to become more continuous. SleepSpace can help with schedule tuning, relaxation tools for middle-of-the-night wakefulness, and personalized insights from your diary.",
      cta_title: "Reconnect the broken parts of your night",
      cta_body: "SleepSpace helps you reduce wakeups, lower nighttime arousal, and rebuild more continuous sleep.",
      image: "animal-frog.png"
    ),
    sparrow_too_early_riser: phenotype_data(
      key: :sparrow_too_early_riser,
      animal_name: "Sparrow",
      title: "Too-Early Riser",
      hook: "Your body clock may be ending the night before you are done recovering.",
      description: "You may wake up earlier than you want and struggle to get back to sleep. This can happen with stress, circadian timing, or a sleep window that is subtly misaligned with your biology. Over time, it can create the feeling that your nights are cut short even when you are trying hard to do everything right. The solution is often less about force and more about rhythm. When this phenotype improves, mornings stop feeling like an unwanted early ending and start feeling like a natural wake-up.",
      ideal_next_step: "Work on timing, light exposure, and consistency. SleepSpace can help you shape a schedule that supports a later final awakening without making nights feel effortful.",
      cta_title: "Stretch the night in the right direction",
      cta_body: "Use SleepSpace to fine-tune your sleep timing and support more complete overnight recovery.",
      image: "animal-sparrow.png"
    ),
    cat_napper_rebounder: phenotype_data(
      key: :cat_napper_rebounder,
      animal_name: "Cat",
      title: "Napper Rebounder",
      hook: "Your system is trying to recover wherever it can.",
      description: "You may be borrowing wakefulness from naps, caffeine, or short bursts of energy. That can help you get through the day, but it can also make nights less consolidated and blur your true sleep need. Your pattern suggests recovery pressure is building and getting paid back in uneven ways. What you need most is a more stable rhythm, not just more random rest. The goal is to move from opportunistic recovery to recovery your body can actually count on.",
      ideal_next_step: "Reduce rebound sleep behaviors and make recovery more predictable. SleepSpace can help you build a steadier routine so sleep pressure lands where it belongs at night.",
      cta_title: "Stop chasing energy and start rebuilding it",
      cta_body: "SleepSpace helps you turn scattered recovery into a more stable night-to-night sleep pattern.",
      image: "animal-cat.png"
    ),
    weasel_fragmented_ruminator: phenotype_data(
      key: :weasel_fragmented_ruminator,
      animal_name: "Weasel",
      title: "Fragmented Ruminator",
      hook: "Your sleep keeps getting interrupted by a mind that reopens the day.",
      description: "This profile blends sleep maintenance difficulty with mental reactivation. You may fall asleep, wake during the night, and then find that thinking rushes back in before sleep does. Nights can feel mentally sticky rather than physically restless. The best path forward is to reduce both nighttime arousal and the number of openings your brain uses to start thinking again. This phenotype usually benefits from making the middle of the night feel less cognitively available.",
      ideal_next_step: "Target both continuity and mental quieting. SleepSpace can help with middle-of-the-night audio, schedule stability, and structured thought-offloading.",
      cta_title: "Close the loops that reopen at 2 AM",
      cta_body: "Use SleepSpace to reduce overnight reactivation and make it easier to settle back into sleep.",
      image: "animal-weasel.png",
      secondary_links: [CBTI_LINK]
    ),

    owl_true_night_owl: phenotype_data(
      key: :owl_true_night_owl,
      animal_name: "Owl",
      title: "True Night Owl",
      hook: "You are not broken. Your clock simply runs later.",
      description: "You naturally feel sharper later in the day and may do some of your best thinking at night. Trouble begins when life expects an early-morning version of you that does not match your biology. This can create chronic sleep debt even when your schedule makes perfect sense to your body. The goal is not to erase your rhythm, but to make it work better with real life. When supported well, this phenotype can become a strength instead of a constant source of social jet lag.",
      ideal_next_step: "Protect consistency and strategically use light, timing, and routines. SleepSpace can help late chronotypes get better sleep without feeling like they have to become someone else.",
      cta_title: "Optimize a later body clock",
      cta_body: "Use SleepSpace to work with your rhythm, improve consistency, and reduce the cost of living on a later schedule.",
      image: "animal-owl.png",
      secondary_links: [SCIENCE_LINK]
    ),
    lark_morning_sprinter: phenotype_data(
      key: :lark_morning_sprinter,
      animal_name: "Lark",
      title: "Morning Sprinter",
      hook: "Your energy wants to arrive early and be used early.",
      description: "You tend to wake with momentum and may do your best work earlier in the day. This can be a major strength, especially when your sleep remains consistent and protected. Problems usually show up when social or work demands push your bedtime later than your body likes. The right next step is to help your routine support the rhythm you already have. Your sleep is often best when your evenings are protected just as deliberately as your mornings.",
      ideal_next_step: "Protect consistency and avoid creeping bedtime delays. SleepSpace can help reinforce your rhythm and prevent early-morning wakefulness from turning into shortened nights.",
      cta_title: "Lock in your strongest hours",
      cta_body: "SleepSpace helps early chronotypes protect sleep quality and keep mornings feeling sharp.",
      image: "animal-lark.png"
    ),
    fox_irregular_schedule: phenotype_data(
      key: :fox_irregular_schedule,
      animal_name: "Fox",
      title: "Irregular Schedule Sleeper",
      hook: "Your sleep is adapting to a moving target.",
      description: "Your bedtime, wake time, or day structure changes enough that your sleep rhythm has trouble getting anchored. Even when total sleep looks reasonable, inconsistency can make your nights feel less restorative and your mornings less predictable. This pattern is common when work, caregiving, social demands, or variable routines keep moving the goalposts. The biggest win usually comes from creating a few anchors your body can rely on. A small amount of regularity often helps this phenotype more than a large amount of effort.",
      ideal_next_step: "Start by stabilizing one or two non-negotiable timing cues. SleepSpace can help you create a realistic schedule with enough flexibility to fit your life without losing rhythm.",
      cta_title: "Give your body a rhythm it can trust",
      cta_body: "SleepSpace helps variable schedules feel less chaotic by creating better anchors for sleep timing and recovery.",
      image: "animal-fox.png"
    ),
    gazelle_jet_lag_hopper: phenotype_data(
      key: :gazelle_jet_lag_hopper,
      animal_name: "Gazelle",
      title: "Jet-Lag Hopper",
      hook: "You may be sleeping in multiple time zones, even when your body is still in the last one.",
      description: "Frequent travel or repeated time-zone shifts can make sleep feel detached from home base. You may be tired at the wrong times, hungry at odd hours, and unable to predict when your body will actually feel ready for sleep. This is not just inconvenience. It is a real circadian stressor. Strategic light, schedule shifts, and pre-travel planning can make a big difference. The more portable your recovery system becomes, the less every trip has to feel like starting over.",
      ideal_next_step: "Use travel-specific circadian support. SleepSpace can help you align light, sound, and timing to reduce the drag of jet lag and help your body adapt faster.",
      cta_title: "Travel with less circadian whiplash",
      cta_body: "SleepSpace can help you land faster, recover faster, and sleep better when time zones keep shifting.",
      image: "animal-gazelle.png"
    ),
    bat_shift_worker: phenotype_data(
      key: :bat_shift_worker,
      animal_name: "Bat",
      title: "Shift Worker",
      hook: "Your sleep has to perform under conditions biology did not design for.",
      description: "Shift work or rotating schedules can make sleep feel fragmented, mistimed, or always slightly off. You may do everything right and still feel like your body clock is pushing back. That does not mean there is no solution. It means you need tools designed for circadian disruption, not generic sleep advice. This phenotype improves when sleep is treated like a protected recovery block rather than an afterthought squeezed between obligations.",
      ideal_next_step: "Use strategic routines for off-hours sleep and alertness. SleepSpace can help shift workers improve consistency, wind down faster, and create a more sleep-friendly environment even when the clock is unfriendly.",
      cta_title: "Sleep better on a schedule that fights back",
      cta_body: "SleepSpace gives shift workers practical tools for circadian disruption, recovery, and better daytime functioning.",
      image: "animal-bat.png"
    ),
    wolf_delayed_clock: phenotype_data(
      key: :wolf_delayed_clock,
      animal_name: "Wolf",
      title: "Delayed Clock",
      hook: "Your biology is pulling the night later than your life comfortably allows.",
      description: "This is a stronger delayed-timing phenotype than a general night owl pattern. Your body seems to resist sleep until later hours, and the mismatch can show up as long sleep latency, social jet lag, or chronic short sleep on workdays. The aim is not forcing an early identity overnight. It is strategically nudging the clock while protecting recovery. The most sustainable changes here usually feel gradual, biological, and precise rather than strict or punishing.",
      ideal_next_step: "Use light, timing, and consistency as circadian levers. SleepSpace can help you shift later timing more intentionally and reduce the cost of delay.",
      cta_title: "Bring a delayed clock closer to real life",
      cta_body: "Use SleepSpace to guide a later body clock with more precision and less frustration.",
      image: "animal-wolf.png",
      secondary_links: [SCIENCE_LINK]
    ),
    coyote_social_jetlagger: phenotype_data(
      key: :coyote_social_jetlagger,
      animal_name: "Coyote",
      title: "Social Jetlagger",
      hook: "Late weekends and early weekdays may be pulling your body clock in opposite directions.",
      description: "This phenotype fits a younger, socially active delayed-sleep pattern where late nights on weekends collide with early weekday wake times. Your body may already prefer a later schedule, and then weekend social timing pushes it even later, making Sunday nights and weekday sleep onset feel frustrating or almost impossible. The result can look like delayed sleep phase syndrome mixed with social jet lag: hard to fall asleep when you need to, hard to wake when life demands it, and a circadian rhythm that never fully settles. The goal is not to erase your social life. It is to reduce the amount of clock whiplash your system has to absorb every week.",
      ideal_next_step: "Start by narrowing the gap between weekend and weekday timing. SleepSpace can help you use light, wind-down routines, and more stable sleep anchors so your circadian rhythm stops getting reset every weekend.",
      cta_title: "Reduce the weekend-to-weekday circadian whiplash",
      cta_body: "Use SleepSpace to make a later social schedule more compatible with real-life mornings and easier sleep onset during the week.",
      image: "animal-coyote.png",
      secondary_links: [SCIENCE_LINK, CBTI_LINK]
    ),
    eagle_advanced_clock: phenotype_data(
      key: :eagle_advanced_clock,
      animal_name: "Eagle",
      title: "Advanced Clock",
      hook: "Your internal morning may be arriving before your ideal schedule does.",
      description: "This profile reflects a stronger advanced circadian pattern. You may get sleepy early, wake very early, and feel like the end of the night comes before you are finished recovering. The key is to respect the strength of your timing signal while deciding where it needs support. Tiny changes in light and routine can matter a lot here. The goal is to stop losing recovery simply because your clock is eager to start the day before you are ready.",
      ideal_next_step: "Tune evening cues and protect the back half of the night. SleepSpace can help with consistency, light timing, and schedule adjustments that reduce premature morning wakefulness.",
      cta_title: "Keep an early clock from ending the night too soon",
      cta_body: "SleepSpace helps advanced-timing sleepers extend recovery without turning sleep into a fight.",
      image: "animal-eagle.png"
    ),
    mole_free_running_clock: phenotype_data(
      key: :mole_free_running_clock,
      animal_name: "Mole",
      title: "Free-Running Clock",
      hook: "Your schedule signal may be drifting enough that your body clock is hard to pin down.",
      description: "This phenotype fits when sleep timing keeps sliding rather than staying anchored to a stable day. It can feel like your sleep schedule keeps moving out from under you, making routines harder to trust. The goal is to reintroduce strong anchors that tell the circadian system what day and night are supposed to mean. For this phenotype, consistency is not cosmetic. It is the signal that helps the whole system stop drifting.",
      ideal_next_step: "Strengthen time cues and remove drift where possible. SleepSpace can help you rebuild schedule anchors around light, consistency, and routine.",
      cta_title: "Stop the clock from wandering",
      cta_body: "Use SleepSpace to anchor timing and reduce circadian drift when your schedule will not stay put.",
      image: "animal-mole.png",
      secondary_links: [SCIENCE_LINK]
    ),

    horse_workhorse_restricted: phenotype_data(
      key: :horse_workhorse_restricted,
      animal_name: "Horse",
      title: "Workhorse Sleeper",
      hook: "Your main sleep problem may not be sleep. It may be time.",
      description: "You appear capable of sleeping, but your life may not be leaving enough room for it. Workload, obligations, and long active days can create a pattern where sleep becomes compressed, rushed, or borrowed against. Many people in this category feel functional until they realize how much better they operate with enough recovery. The right next step is to reclaim sleep as a performance tool, not treat it like leftover time. This phenotype often improves first through boundary-setting, not through more sleep hacks.",
      ideal_next_step: "Protect sleep quantity first, then optimize quality. SleepSpace can help you find a more realistic bedtime, reduce sleep debt, and make the sleep you do get more restorative.",
      cta_title: "Get more out of the sleep you are short on",
      cta_body: "SleepSpace helps busy people recover faster, build better habits, and stop running on chronic sleep debt.",
      image: "animal-horse.png"
    ),
    camel_sleep_debt_carrier: phenotype_data(
      key: :camel_sleep_debt_carrier,
      animal_name: "Camel",
      title: "Sleep Debt Carrier",
      hook: "You have become good at functioning on less sleep than your body actually wants.",
      description: "You may be carrying accumulated sleep debt and compensating with routine, urgency, or willpower. That can make the problem easy to normalize, especially if you are still getting through your day. But chronic short sleep has a way of showing up in mood, patience, focus, appetite, and long-term health. What you need most is not a heroic push. It is recovery that finally catches up. This phenotype usually feels better when catch-up becomes intentional and steady instead of occasional and desperate.",
      ideal_next_step: "Start paying down sleep debt in a sustainable way. SleepSpace can help you make up ground without turning your routine upside down overnight.",
      cta_title: "Catch up without crashing",
      cta_body: "Use SleepSpace to rebuild sleep quantity, reduce rebound fatigue, and recover more consistently.",
      image: "animal-camel.png"
    ),
    kangaroo_new_parent: phenotype_data(
      key: :kangaroo_new_parent,
      animal_name: "Kangaroo",
      title: "New Parent Sleeper",
      hook: "Your sleep is being asked to stay protective, flexible, and interrupted all at once.",
      description: "This pattern is common when nighttime caregiving is part of life. Sleep often becomes lighter, more fragmented, and more reactive because your system is staying available. That does not mean you are doing anything wrong. It means your sleep strategy has to work with disruption instead of pretending it is not there. Recovery here depends on flexibility, self-compassion, and making the sleep you do get easier to re-enter.",
      ideal_next_step: "Focus on damage control and efficient recovery. SleepSpace can help you improve wind-down speed, get more restoration from shorter sleep windows, and find calming routines that still work during disrupted nights.",
      cta_title: "Support your sleep in a season of interruption",
      cta_body: "SleepSpace helps new parents recover faster and make the most of imperfect nights.",
      image: "animal-kangaroo.png"
    ),
    goat_caregiver: phenotype_data(
      key: :goat_caregiver,
      animal_name: "Goat",
      title: "Caregiver Sleeper",
      hook: "Your sleep is carrying more than your own needs.",
      description: "Caregiving can make sleep feel vigilant, shortened, and emotionally loaded. Whether it is a child, partner, or elderly parent, your nights may be shaped by responsibility before they are shaped by recovery. That can create a kind of fatigue that is both physical and emotional. You need solutions that are realistic, not idealized. The best support for this phenotype usually reduces friction and decision fatigue as much as it improves sleep itself.",
      ideal_next_step: "Start with stabilizing what you can control. SleepSpace can help you build a dependable wind-down, improve sleep continuity, and create pockets of recovery inside a demanding routine.",
      cta_title: "Protect your recovery while caring for others",
      cta_body: "SleepSpace can help caregivers sleep more deeply, calm faster, and recover more efficiently between interruptions.",
      image: "animal-goat.png"
    ),
    crow_long_commuter: phenotype_data(
      key: :crow_long_commuter,
      animal_name: "Crow",
      title: "Long-Commuter Sleeper",
      hook: "Your days may be stealing from your nights.",
      description: "When commute time gets long, sleep is often the first thing that gets compressed. Even a decent routine can become hard to sustain when your schedule is stretched at both ends. This pattern often creates a steady, low-grade sleep debt that feels normal until it is not. Reclaiming even a small amount of sleep time can create a surprisingly large improvement. For this phenotype, minutes matter because the schedule is already running with very little margin.",
      ideal_next_step: "Find one or two points in the day where recovery can be protected. SleepSpace can help make your nights more efficient and your schedule more sleep-supportive.",
      cta_title: "Steal back recovery from a long day",
      cta_body: "SleepSpace helps make limited sleep windows more restorative and easier to protect.",
      image: "animal-crow.png"
    ),
    duck_sandwich_generation: phenotype_data(
      key: :duck_sandwich_generation,
      animal_name: "Duck",
      title: "Sandwich-Generation Sleeper",
      hook: "Your nights are being squeezed from more than one direction.",
      description: "This pattern fits people who are supporting older family members while still handling children, work, or both. Sleep becomes fragmented not just by interruption, but by relentless responsibility. Recovery often feels like something you keep postponing. The right plan is realistic triage plus routines that restore you efficiently. This phenotype often needs permission to prioritize restoration even when everyone else seems louder and more urgent.",
      ideal_next_step: "Simplify the recovery plan and protect one reliable anchor. SleepSpace can help you create calmer transitions and better use short sleep windows.",
      cta_title: "Support the sleeper supporting everyone else",
      cta_body: "Use SleepSpace to make recovery more efficient during a life season that leaves little margin.",
      image: "animal-duck.png"
    ),
    ant_overtime_grinder: phenotype_data(
      key: :ant_overtime_grinder,
      animal_name: "Ant",
      title: "Overtime Grinder",
      hook: "Your sleep is being compressed by sustained output, not by lack of sleep ability.",
      description: "This profile reflects persistent overwork, long shifts, or multiple roles packed into the same day. The result is a body that could sleep but rarely gets enough opportunity to do it. Fatigue can feel baked into the lifestyle. The goal is to reclaim enough regular recovery that the system can stop white-knuckling through the week. The most meaningful improvements usually come from reducing chronic overload, not simply trying to tolerate it better.",
      ideal_next_step: "Start with one realistic schedule gain and protect it fiercely. SleepSpace can help you turn limited time into higher-quality recovery.",
      cta_title: "Take sleep off the overtime chopping block",
      cta_body: "SleepSpace helps high-output schedules create more recovery without pretending life is suddenly easy.",
      image: "animal-ant.png"
    ),
    mule_heavy_load_sleeper: phenotype_data(
      key: :mule_heavy_load_sleeper,
      animal_name: "Mule",
      title: "Heavy-Load Sleeper",
      hook: "You are carrying enough daily load that sleep has become part recovery, part survival.",
      description: "This profile is less about a single issue and more about cumulative burden. Long days, emotional load, caregiving, work, and low margin can all stack together until sleep feels utilitarian instead of restorative. You need a system that respects the weight you are carrying while still helping recovery improve. This phenotype benefits most from sleep support that lowers effort and adds restoration without asking for perfection.",
      ideal_next_step: "Focus on reliability over perfection. SleepSpace can help create a more repeatable wind-down and better continuity under real-life load.",
      cta_title: "Make recovery sturdier under pressure",
      cta_body: "Use SleepSpace to rebuild steadier sleep when your days are heavy and your nights have to do more.",
      image: "animal-mule.png"
    ),

    bulldog_airway_clencher: phenotype_data(
      key: :bulldog_airway_clencher,
      animal_name: "Bulldog",
      title: "Airway Clencher",
      hook: "Your sleep may be getting disrupted by breathing, snoring, or nighttime airway strain.",
      description: "If you snore loudly, grind, or feel out of breath during sleep, there may be a sleep-breathing issue worth taking seriously. People with this pattern often wake unrefreshed even when they appear to be spending enough time in bed. Nighttime breathing disruption can quietly fracture sleep quality and daytime energy. This is one of the most important patterns to follow up on promptly. The name of this phenotype is meant to signal that breathing quality may be the hidden bottleneck in the entire recovery system.",
      ideal_next_step: "Consider screening for sleep apnea or a related breathing issue while improving your sleep environment now. SleepSpace can help optimize your schedule, wind-down, and recovery habits while you pursue the right evaluation.",
      cta_title: "Do not ignore a breathing-related sleep signal",
      cta_body: "SleepSpace can support better sleep quality and healthier routines while you investigate the breathing side of the picture.",
      image: "animal-bulldog.png",
      secondary_links: [SCIENCE_LINK]
    ),
    walrus_thunder_snorer: phenotype_data(
      key: :walrus_thunder_snorer,
      animal_name: "Walrus",
      title: "Thunder Snorer",
      hook: "Snoring may be the loud symptom of a quieter quality problem.",
      description: "You may be someone whose nights sound more disrupted than they look. Even when snoring is not severe apnea, it can still point to airway resistance, dry sleep, or poorer overnight restoration. Many people underestimate how much snoring affects recovery until they improve it. Small changes can matter, and persistent symptoms deserve follow-up. This phenotype is a reminder that noisy sleep is often still meaningful sleep disruption.",
      ideal_next_step: "Treat snoring like useful information, not just a nuisance. SleepSpace can help improve sleep hygiene, schedule, and environment while you monitor whether breathing-related symptoms continue.",
      cta_title: "Improve the quality hiding underneath the noise",
      cta_body: "SleepSpace helps you improve overall recovery while you get clearer about what snoring is doing to your nights.",
      image: "animal-walrus.png"
    ),
    porcupine_pain_tosser: phenotype_data(
      key: :porcupine_pain_tosser,
      animal_name: "Porcupine",
      title: "Pain Tosser",
      hook: "Your body may be interrupting your sleep before your brain gets the chance to settle.",
      description: "Pain-driven sleep disruption often looks like frequent position changes, light sleep, short awakenings, or difficulty staying comfortable long enough to rest deeply. That can become frustrating because it makes bedtime feel effortful and recovery incomplete. When pain and sleep feed each other, nights often need a more supportive strategy. The right solution usually combines comfort, routine, and a more calming sleep environment. Better sleep here often begins with reducing the amount of negotiation your body has to do all night long.",
      ideal_next_step: "Focus on making sleep easier on your body and less reactive for your brain. SleepSpace can support pre-sleep relaxation, environmental optimization, and a more restorative nightly pattern.",
      cta_title: "Help your body stop interrupting the night",
      cta_body: "Use SleepSpace to create a calmer, more restorative routine when pain is getting in the way of sleep.",
      image: "animal-porcupine.png"
    ),
    meerkat_noise_guard: phenotype_data(
      key: :meerkat_noise_guard,
      animal_name: "Meerkat",
      title: "Noise Guard",
      hook: "Your sleep stays on alert for the next disturbance.",
      description: "You seem highly sensitive to noise, light, or environmental unpredictability. Instead of fully powering down, your system keeps monitoring the space around you, which can make sleep lighter and more fragmented. This is especially common when you are stressed or sleeping in a noisy environment. Better sleep for you usually begins with making the room feel more predictable and safe. For this phenotype, environmental calm is not a luxury. It is often the entry ticket to deeper sleep.",
      ideal_next_step: "Reduce environmental triggers and help your nervous system lower its guard. SleepSpace can layer sound, consistency, and calming routines to make sleep easier to stay in.",
      cta_title: "Help your room feel quieter to your nervous system",
      cta_body: "SleepSpace can help you reduce environmental reactivity and sleep more continuously through the night.",
      image: "animal-meerkat.png"
    ),
    penguin_partner_poked: phenotype_data(
      key: :penguin_partner_poked,
      animal_name: "Penguin",
      title: "Partner-Poked Sleeper",
      hook: "Your sleep may be shaped by whoever or whatever shares the night with you.",
      description: "When a partner, pet, or co-sleeper interrupts your nights, the issue is not always your biology. It may be the sleep environment itself. These interruptions can slowly erode continuity and leave you less recovered than your schedule suggests. Solutions often come from reducing friction around the shared sleep space rather than trying to force yourself to sleep through it. This phenotype improves when shared sleep becomes more intentional and less improvisational.",
      ideal_next_step: "Make the shared environment more sleep-friendly. SleepSpace can help with sound masking, routine building, and strategies for keeping disruptions from fully breaking the night apart.",
      cta_title: "Protect your side of the bed",
      cta_body: "Use SleepSpace to create a more resilient sleep setup, even when the night is not entirely yours.",
      image: "animal-penguin.png"
    ),
    lizard_heat_kicker: phenotype_data(
      key: :lizard_heat_kicker,
      animal_name: "Lizard",
      title: "Heat Kicker",
      hook: "Your nights may be getting interrupted by temperature, sweating, or heat buildup.",
      description: "Waking up sweaty or too warm can quietly degrade sleep quality and make the night feel less stable. Even small thermal discomfort can increase awakenings and keep deeper sleep from fully consolidating. Many people do not realize how much temperature is shaping their sleep until they change it. Your next step is to make the environment work with your body instead of against it. Cooler, steadier nights often create outsized gains for this phenotype because temperature keeps nudging sleep back toward the surface.",
      ideal_next_step: "Cool the room, simplify bedding, and support smoother nighttime temperature regulation. SleepSpace can help by pairing routines and environmental support to create a more stable sleep window.",
      cta_title: "Cool the room, calm the night",
      cta_body: "SleepSpace helps you turn a disruptive sleep environment into one that supports deeper, steadier rest.",
      image: "animal-lizard.png"
    ),
    armadillo_restless_legs: phenotype_data(
      key: :armadillo_restless_legs,
      animal_name: "Armadillo",
      title: "Restless-Legs Sleeper",
      hook: "Your body may be asking you to move right when you want it to settle.",
      description: "This profile fits nights disrupted by leg sensations, urges to move, or repeated settling attempts. The result is often delayed sleep onset, fragmented rest, or a sense that sleep never quite stabilizes. Because the issue is physical and rhythmic, people often blame themselves unnecessarily. Better sleep starts by respecting the body signal and reducing how much it steals from the night. The more seriously the body cue is taken, the less chaotic bedtime usually becomes.",
      ideal_next_step: "Track when movement symptoms rise and protect the transition into sleep. SleepSpace can support calmer bedtime routines and a more sleep-friendly setup around restless nights.",
      cta_title: "Help your body stop restarting bedtime",
      cta_body: "Use SleepSpace to protect sleep continuity when physical restlessness keeps interrupting the night.",
      image: "animal-armadillo.png"
    ),
    whale_altitude_breather: phenotype_data(
      key: :whale_altitude_breather,
      animal_name: "Whale",
      title: "Altitude Breather",
      hook: "Your nights may feel lighter or more broken when oxygen and pressure cues change.",
      description: "This profile fits sleep that becomes more difficult with altitude, thin air, or travel to high elevations. You may feel like your breathing, sleep depth, or overnight stability changes in ways that are hard to explain. Circadian disruption and airway load can both intensify here. The best strategy is to make recovery more supportive while your body adapts. This phenotype does best when the environment is treated like part of the sleep challenge rather than just the backdrop.",
      ideal_next_step: "Use environmental support and protect routine during altitude-related change. SleepSpace can help stabilize the other parts of sleep while your system adjusts.",
      cta_title: "Support sleep when the air feels different",
      cta_body: "SleepSpace helps keep sleep steadier when altitude or oxygen changes are adding stress to the night.",
      image: "animal-whale.png"
    ),

    dolphin_half_awake: phenotype_data(
      key: :dolphin_half_awake,
      animal_name: "Dolphin",
      title: "Half-Awake Sleeper",
      hook: "You are sleeping enough on paper, but not waking up as restored as you should.",
      description: "This pattern often shows up when total sleep time looks fine, but the quality of that sleep is not translating into energy. That can happen because of environment, breathing, schedule mismatch, stress, alcohol, or other hidden disruptors. The important takeaway is that your body is asking for better sleep, not necessarily more sleep. The next step is to improve quality in a targeted way. This phenotype often shifts once the invisible sources of fragmentation are finally named and addressed.",
      ideal_next_step: "Use your diary and routines to identify what is lowering sleep quality. SleepSpace can help you tighten your environment, personalize your wind-down, and make your nights feel more restorative.",
      cta_title: "Get more recovery from the same night",
      cta_body: "SleepSpace helps uncover what is lowering sleep quality and gives you tools to start improving it quickly.",
      image: "animal-dolphin.png",
      secondary_links: [SCIENCE_LINK]
    ),
    hawk_precision_performer: phenotype_data(
      key: :hawk_precision_performer,
      animal_name: "Hawk",
      title: "Precision Performer",
      hook: "You are already functioning, but you want your sleep to sharpen performance.",
      description: "Your pattern suggests that sleep is less about fixing a major problem and more about unlocking a higher ceiling. You may care about cognition, exercise, reaction time, consistency, or next-day effectiveness. That is a great place to be, because small improvements can create outsized gains when your baseline is already decent. The next step is to make your routine more intentional and measurable. This phenotype responds especially well when recovery is treated as part of training rather than something separate from it.",
      ideal_next_step: "Use SleepSpace to translate good sleep into better performance. Focus on consistency, wind-down quality, and the environmental levers that can raise the floor and the ceiling of how you feel.",
      cta_title: "Turn decent sleep into a performance advantage",
      cta_body: "SleepSpace helps high performers improve recovery, consistency, and next-day readiness.",
      image: "animal-hawk.png",
      secondary_links: [SCIENCE_LINK]
    ),
    otter_balanced_builder: phenotype_data(
      key: :otter_balanced_builder,
      animal_name: "Otter",
      title: "Balanced Builder",
      hook: "You already have a workable foundation. Now it is about refinement.",
      description: "Your sleep does not look severely disrupted, but there is room to make it more reliable, more restorative, or better matched to your goals. This is often where personalization matters most. Generic sleep tips may not move the needle much, but targeted changes often do. Your next step is optimization, not overhaul. What makes this phenotype exciting is that subtle changes can meaningfully improve already decent nights.",
      ideal_next_step: "Use SleepSpace to tune the details. Improve your schedule, wind-down, sound environment, and sleep awareness so good sleep becomes more repeatable.",
      cta_title: "Build from stable to excellent",
      cta_body: "SleepSpace helps solid sleepers get more consistent and more personalized results from their nights.",
      image: "animal-otter.png"
    ),
    koala_long_sleep_restorer: phenotype_data(
      key: :koala_long_sleep_restorer,
      animal_name: "Koala",
      title: "Long-Sleep Restorer",
      hook: "Your body may simply need more time asleep than average to feel fully recharged.",
      description: "Some people genuinely do best with a longer sleep window. That does not automatically mean something is wrong. If your body consistently feels better with more sleep, your goal should be to protect that need rather than argue with it. The best next step is to improve depth and consistency so your longer sleep window feels worth it. This phenotype does best when quantity and quality are allowed to work together instead of being traded against each other.",
      ideal_next_step: "Honor your sleep need and make it more efficient. SleepSpace can help deepen sleep quality so your natural recovery style works even better.",
      cta_title: "Support the amount of sleep your body actually wants",
      cta_body: "Use SleepSpace to make a longer sleep need feel more restorative and more sustainable.",
      image: "animal-koala.png"
    ),
    elephant_short_sleep_ace: phenotype_data(
      key: :elephant_short_sleep_ace,
      animal_name: "Elephant",
      title: "Short-Sleep Ace",
      hook: "You may naturally operate well on less sleep than most people.",
      description: "A small minority of people appear to need less sleep while still functioning well. If that is truly you, the goal is not to force extra time in bed. It is to protect quality and notice early if stress starts pushing your short-sleep pattern into sleep debt. Your sleep may already be efficient. The next step is to keep it that way. The key is distinguishing true efficiency from silent under-recovery, especially when life gets demanding.",
      ideal_next_step: "Preserve efficiency and prevent silent drift into under-recovery. SleepSpace can help you keep quality high and spot changes before they become problems.",
      cta_title: "Protect an efficient sleep style",
      cta_body: "SleepSpace helps natural short sleepers maintain high-quality recovery without overcomplicating the process.",
      image: "animal-elephant.png"
    ),
    bear_consistent_restorer: phenotype_data(
      key: :bear_consistent_restorer,
      animal_name: "Bear",
      title: "Consistent Restorer",
      hook: "You have the kind of sleep foundation most people are trying to build.",
      description: "Your pattern looks steady, restorative, and aligned with your needs. That does not mean you are done. It means you have a strong base to protect and optimize. The biggest opportunity for you is to stay consistent and make small changes that strengthen recovery even more. This phenotype is less about repair and more about preserving something already working well.",
      ideal_next_step: "Use SleepSpace as a smart layer on top of a healthy routine. Fine-tune your environment, bedtime rhythm, and recovery habits so good sleep stays good.",
      cta_title: "Keep great sleep working for you",
      cta_body: "SleepSpace helps healthy sleepers protect consistency and push recovery even further.",
      image: "animal-bear.png",
      secondary_links: [SCIENCE_LINK]
    ),
    dog_flexible_sleeper: phenotype_data(
      key: :dog_flexible_sleeper,
      animal_name: "Dog",
      title: "Flexible Sleeper",
      hook: "Your sleep appears resilient, adaptable, and generally healthy.",
      description: "You seem able to sleep reasonably well without needing perfect conditions every single night. That flexibility is a strength. It often means your baseline recovery system is solid. Your best next step is to make sure flexibility does not slowly turn into inconsistency. Resilience is powerful here, but it works best when it is supported by just enough structure.",
      ideal_next_step: "Use SleepSpace to stay aware of subtle drift and reinforce habits that keep your sleep strong over time. Optimization is likely to feel simple and rewarding for you.",
      cta_title: "Strengthen what is already working",
      cta_body: "SleepSpace helps flexible sleepers stay consistent, recover well, and keep healthy patterns from eroding over time.",
      image: "animal-dog.png"
    ),
    lion_deep_sleep_athlete: phenotype_data(
      key: :lion_deep_sleep_athlete,
      animal_name: "Lion",
      title: "Deep-Sleep Athlete",
      hook: "Your system looks built for intense output followed by equally serious recovery.",
      description: "This phenotype fits people who push hard physically and then drop into unusually restorative sleep. You may train intensely, stay highly active, or demand a lot from your body during the day, but your nights appear to answer with deep, efficient recovery. The opportunity here is not fixing broken sleep. It is preserving the habits that let high output and deep restoration reinforce each other. In many ways, this phenotype represents sleep functioning as a true extension of elite training.",
      ideal_next_step: "Use SleepSpace to protect the recovery rituals that keep performance sustainable. Focus on consistency, training-day recovery patterns, and environmental cues that support deep sleep.",
      cta_title: "Protect elite physical recovery",
      cta_body: "SleepSpace helps high-output sleepers preserve deep recovery, consistency, and next-day readiness.",
      image: "animal-lion.png",
      secondary_links: [SCIENCE_LINK]
    ),
    raven_cognitive_marathoner: phenotype_data(
      key: :raven_cognitive_marathoner,
      animal_name: "Raven",
      title: "Cognitive Marathoner",
      hook: "Your brain works hard, and your sleep seems designed to restore it.",
      description: "This profile fits people who carry heavy mental load but still recover well at night. You may spend your days in analysis, strategy, creativity, study, or focused problem-solving, and your nights appear to support that cognitive intensity with strong sleep depth and consistency. The goal is to keep that brain-body recovery loop intact so high mental performance stays sustainable. This phenotype works best when mental intensity is balanced by deliberate decompression rather than endless stimulation.",
      ideal_next_step: "Use SleepSpace to reinforce the timing, decompression, and rhythm that keep cognitive performance paired with deep restoration.",
      cta_title: "Support a high-output brain with better recovery",
      cta_body: "SleepSpace helps mentally intense sleepers protect the routines that keep focus, clarity, and recovery strong.",
      image: "animal-raven.png",
      secondary_links: [SCIENCE_LINK]
    ),
    panther_dream_weaver: phenotype_data(
      key: :panther_dream_weaver,
      animal_name: "Panther",
      title: "Dream Weaver",
      hook: "Your dream life is not random noise. It is part of how you recover, process, and explore.",
      description: "This phenotype captures people whose sleep is both restorative and dream-rich. You may remember dreams easily, care about lucid dreaming, or treat dreaming as a doorway into creativity, insight, or consciousness work. Unlike a distress-driven dream phenotype, this one reflects stable sleep with a strong inner landscape. The key is to support that richness without disrupting the structure of sleep underneath it. For this phenotype, dreaming is not just something that happens during sleep. It is part of how sleep feels meaningful.",
      ideal_next_step: "Use SleepSpace to strengthen dream recall, sleep depth, and overnight stability so your dream practice enhances recovery instead of competing with it.",
      cta_title: "Turn dreaming into a recovery skill",
      cta_body: "SleepSpace helps dream-focused sleepers protect deep sleep while building a healthier and more intentional dream practice.",
      image: "animal-panther.png"
    ),
    crane_zen_meditator: phenotype_data(
      key: :crane_zen_meditator,
      animal_name: "Crane",
      title: "Zen Meditator",
      hook: "Calm is not something you chase at night. It is something you have trained.",
      description: "This pattern fits people who use meditation, mindfulness, breathwork, or similar practices to create unusually calm and restorative sleep. Your nights may feel spacious, steady, and less reactive than average because you have taught your nervous system how to settle. That is a meaningful strength. The next step is to preserve the rituals and timing that let that calm translate into real biological recovery. This phenotype often reflects a rare overlap between conscious practice and genuinely resilient sleep physiology.",
      ideal_next_step: "Use SleepSpace to deepen the connection between mindfulness and sleep quality. Keep your rhythm consistent and layer in audio or meditation support when life gets noisy.",
      cta_title: "Keep calm sleep deeply restorative",
      cta_body: "SleepSpace helps meditation-oriented sleepers maintain steady, high-quality recovery even when stress rises.",
      image: "animal-crane.png"
    ),
    stag_recovery_alchemist: phenotype_data(
      key: :stag_recovery_alchemist,
      animal_name: "Stag",
      title: "Recovery Alchemist",
      hook: "You treat sleep as a lever for energy, consciousness, and whole-system restoration.",
      description: "This phenotype fits people who intentionally shape sleep as part of a broader mind-body practice. You may combine tracking, performance goals, meditation, dream work, or recovery rituals to make sleep more than passive rest. When that approach is grounded in a strong sleep foundation, it can create a rare level of alignment between body, mind, and next-day function. Your opportunity is refinement, not rescue. The best version of this phenotype stays curious and precise without becoming controlling or overengineered.",
      ideal_next_step: "Use SleepSpace to keep your optimization grounded in real recovery. Track what genuinely improves sleep depth, next-day clarity, and nervous-system steadiness.",
      cta_title: "Refine sleep as a mind-body practice",
      cta_body: "SleepSpace helps intentional optimizers turn sleep into a cleaner, more measurable recovery advantage.",
      image: "animal-stag.png",
      secondary_links: [SCIENCE_LINK, COACHING_LINK]
    ),
    peacock_sleep_paralysis: phenotype_data(
      key: :peacock_sleep_paralysis,
      animal_name: "Peacock",
      title: "Sleep-Paralysis Sleeper",
      hook: "Some of your most unsettling sleep experiences may be happening at the edges of sleep itself.",
      description: "This profile fits episodes of waking awareness with temporary inability to move, often paired with vivid sensations or fear. These experiences can make sleep feel less safe even when the rest of the night looks normal. The goal is to reduce instability around sleep transitions and lower the fear they create. Naming the pattern clearly can itself be relieving because it makes the experience feel less mysterious and isolating.",
      ideal_next_step: "Reduce sleep deprivation, stabilize timing, and make transitions into sleep feel calmer. SleepSpace can help reinforce steadier patterns around sleep onset and waking.",
      cta_title: "Make sleep transitions feel safer again",
      cta_body: "Use SleepSpace to stabilize sleep timing and lower the arousal that can amplify edge-of-sleep experiences.",
      image: "animal-peacock.png"
    ),
    shark_half_alert: phenotype_data(
      key: :shark_half_alert,
      animal_name: "Shark",
      title: "Half-Alert Sleeper",
      hook: "Your nights seem to stay partially watchful instead of fully off duty.",
      description: "This profile reflects a mix of physiologic and environmental alertness. Sleep may happen, but it feels guarded, shallow, or easy to fracture. People in this category often wake tired despite enough time in bed because the system never fully surrenders into rest. The next step is reducing threat signals from both body and environment. This phenotype improves when sleep begins to feel like a place of safety instead of surveillance.",
      ideal_next_step: "Create stronger cues of safety at night and investigate physical disruptors that may be keeping sleep half-alert.",
      cta_title: "Help sleep stop standing watch",
      cta_body: "SleepSpace can help calm environmental and behavioral factors when your nights never quite power down.",
      image: "animal-shark.png"
    ),
    platypus_dream_actor: phenotype_data(
      key: :platypus_dream_actor,
      animal_name: "Platypus",
      title: "Dream Actor",
      hook: "Your dreaming system may sometimes be crossing into movement or action.",
      description: "This profile fits nights with dream enactment, physical movement, or unusually active REM-related behavior. Even when episodes are occasional, they can make sleep feel less predictable and sometimes less safe. The main goal is to reduce risk, improve sleep stability, and understand whether the pattern is intensifying. Support here starts with making the night safer while paying close attention to how often the pattern returns.",
      ideal_next_step: "Prioritize safety around the sleep environment and improve nightly stability. SleepSpace can support calmer, more consistent nights while you monitor the pattern.",
      cta_title: "Make active dream nights more manageable",
      cta_body: "Use SleepSpace to support steadier sleep when dream activity is crossing into the body.",
      image: "animal-platypus.png"
    ),
    monkey_dream_intense: phenotype_data(
      key: :monkey_dream_intense,
      animal_name: "Monkey",
      title: "Intense Dream Sleeper",
      hook: "Your nights may feel crowded with vivid, memorable, or emotionally loaded dreaming.",
      description: "This profile fits people whose dreams are especially vivid, frequent, or impactful on how sleep feels. Even without movement, intense dreaming can make sleep feel busy rather than deeply restorative. Stress, timing changes, and rebound sleep can all intensify the effect. The right next step is to make overall sleep more stable and less reactive. The goal is not to suppress dreaming completely, but to keep it from dominating the emotional tone of the night.",
      ideal_next_step: "Reduce instability that may be amplifying dream intensity. SleepSpace can help with timing, wind-down, and overnight continuity.",
      cta_title: "Turn busy dream nights into calmer sleep",
      cta_body: "Use SleepSpace to support deeper, steadier sleep when dreams are taking up too much of the night.",
      image: "animal-monkey.png"
    ),
    turtle_slow_starter: phenotype_data(
      key: :turtle_slow_starter,
      animal_name: "Turtle",
      title: "Slow-Starter Sleeper",
      hook: "Your sleep may end, but your system does not feel fully online right away.",
      description: "This pattern fits strong sleep inertia or especially groggy wake-ups. You may feel like your brain and body take too long to fully start, even after enough time asleep. That can reflect timing mismatch, sleep debt, or poor-quality final sleep. Better mornings often start with better endings to the night. This phenotype improves when wake-up becomes a transition your nervous system can anticipate instead of endure.",
      ideal_next_step: "Support the last part of the night and the first minutes of the day more intentionally. SleepSpace can help tune timing and morning transition habits.",
      cta_title: "Make mornings less sticky",
      cta_body: "Use SleepSpace to support cleaner wake-ups when sleep inertia is blunting the start of the day.",
      image: "animal-turtle.png"
    ),
    phoenix_rebound_sleeper: phenotype_data(
      key: :phoenix_rebound_sleeper,
      animal_name: "Phoenix",
      title: "Rebound Sleeper",
      hook: "Your body is trying to recover in bursts after too much accumulated loss.",
      description: "This profile reflects a cycle of under-sleeping followed by catch-up behavior, long sleeps, naps, or heavy fatigue swings. Rebound recovery can help in the short term, but it also keeps the system unstable if it becomes the norm. What your body wants is not another heroic reset. It wants a steadier baseline. The real win for this phenotype is making recovery less dramatic and much more repeatable.",
      ideal_next_step: "Smooth the boom-and-bust cycle and build more even recovery. SleepSpace can help you move from rebound sleep to reliable sleep.",
      cta_title: "Replace rebound with rhythm",
      cta_body: "Use SleepSpace to make recovery steadier when your body keeps trying to rise from sleep debt in bursts.",
      image: "animal-phoenix.png"
    ),
    bee_stress_sensitive: phenotype_data(
      key: :bee_stress_sensitive,
      animal_name: "Bee",
      title: "Stress-Sensitive Sleeper",
      hook: "Your sleep changes quickly when stress levels rise.",
      description: "This profile fits people whose sleep is highly responsive to workload, emotional strain, or periods of overwhelm. Sleep may be decent in calm seasons and much worse in demanding ones. That is useful to know, because it means your sleep system is sensitive, not random. The best plan is one that becomes more supportive before stress peaks, not after. This phenotype benefits from having a stress-season version of your sleep routine ready in advance.",
      ideal_next_step: "Use stress seasons as a cue to increase sleep protection. SleepSpace can help you build routines that buffer sleep before it unravels.",
      cta_title: "Protect sleep before stress gets there first",
      cta_body: "Use SleepSpace to make your sleep system more resilient when life starts getting loud.",
      image: "animal-bee.png"
    ),
    ostrich_escape_sleeper: phenotype_data(
      key: :ostrich_escape_sleeper,
      animal_name: "Ostrich",
      title: "Escape Sleeper",
      hook: "Bedtime may carry enough stress that part of you wants to avoid it.",
      description: "This profile fits people who delay bed, dread the attempt to sleep, or avoid nighttime because sleep has become emotionally loaded. The issue is not laziness. It is that bedtime itself has started to feel like pressure. The right next step is to make the approach to sleep feel less threatening and more winnable. Progress here often begins when bedtime becomes gentler, simpler, and less emotionally charged.",
      ideal_next_step: "Reduce sleep effort and remove pressure from the bedtime ritual. SleepSpace can help turn bedtime back into a gentler transition.",
      cta_title: "Make bedtime feel approachable again",
      cta_body: "Use SleepSpace to lower bedtime stress when your sleep routine has started to feel like something to avoid.",
      image: "animal-ostrich.png",
      secondary_links: [CBTI_LINK]
    ),

    bison_apnea_insomnia: phenotype_data(
      key: :bison_apnea_insomnia,
      animal_name: "Bison",
      title: "Apnea-Insomnia Overlap",
      hook: "Your nights may combine airway strain with trouble falling asleep or settling back down.",
      description: "This overlap profile reflects both breathing-related signals and insomnia-like arousal. People here can feel caught in the middle: tired enough to need help, but too activated or disrupted to sleep smoothly. The right plan usually needs to respect both sides instead of treating the issue as only one or the other. This phenotype is especially important because one problem can easily hide behind the other if you are not looking for both.",
      ideal_next_step: "Treat airway evaluation and insomnia support as parallel tracks. SleepSpace can help stabilize the behavioral side while you investigate breathing-related disruption.",
      cta_title: "Address both sides of the night",
      cta_body: "Use SleepSpace to support more stable sleep while pursuing the right airway follow-up.",
      image: "animal-bison.png",
      secondary_links: [SCIENCE_LINK, CBTI_LINK]
    ),
    crab_back_sleeper: phenotype_data(
      key: :crab_back_sleeper,
      animal_name: "Crab",
      title: "Back-Sleeper Breather",
      hook: "Your sleep may worsen when position changes what your airway has to work against.",
      description: "This profile fits people whose nights seem noticeably worse on their back. Position can change snoring, airway resistance, and how restored sleep feels the next morning. That is useful because position-related problems are often more modifiable than they first appear. This phenotype improves when position stops feeling accidental and starts becoming part of the sleep plan.",
      ideal_next_step: "Notice whether sleep position changes symptoms and build a sleep setup that supports the better pattern.",
      cta_title: "Use position as a lever, not a mystery",
      cta_body: "SleepSpace can help you build a more supportive sleep environment while you learn how position changes the night.",
      image: "animal-crab.png"
    ),
    rhino_explosive_snorer: phenotype_data(
      key: :rhino_explosive_snorer,
      animal_name: "Rhino",
      title: "Explosive Snorer",
      hook: "The volume and force of your snoring may point to a bigger quality issue than it seems.",
      description: "This profile fits very loud, forceful snoring patterns that may be affecting both your sleep and your bed partner's. Even if the issue is normalized socially, it can still signal meaningful airway strain. The key is to take the noise seriously as a recovery clue. In this phenotype, volume is not just annoying. It is useful information about how hard the night may be working.",
      ideal_next_step: "Treat very loud snoring like a meaningful health signal and support the rest of the sleep system while you evaluate it.",
      cta_title: "Take loud snoring seriously",
      cta_body: "Use SleepSpace to improve the sleep conditions around a night that may already be working too hard to breathe.",
      image: "animal-rhino.png"
    ),
    alligator_bruxing_breather: phenotype_data(
      key: :alligator_bruxing_breather,
      animal_name: "Alligator",
      title: "Bruxing Breather",
      hook: "Teeth grinding and breathing strain may be showing up together at night.",
      description: "This overlap profile fits people whose nights include both clenching or grinding and airway-like sleep disruption. The combination can leave mornings feeling tense, dry, or under-recovered. It is a useful pattern to name because it often hides in plain sight. Looking at jaw tension and breathing together often explains more than addressing either one in isolation.",
      ideal_next_step: "Track both jaw-related and breathing-related symptoms and improve the overall sleep environment while you follow up.",
      cta_title: "Look at the jaw and airway together",
      cta_body: "SleepSpace can help support recovery when tension and breathing seem to be sharing the night.",
      image: "animal-alligator.png"
    ),
    boar_alcohol_airway: phenotype_data(
      key: :boar_alcohol_airway,
      animal_name: "Boar",
      title: "Alcohol-Airway Sleeper",
      hook: "Your nights may be getting lighter or noisier when alcohol compounds airway load.",
      description: "This profile fits sleep that becomes noticeably worse after drinking, especially when snoring, breathing, or fragmentation are already in the picture. Alcohol can make sleep feel easier at first while quietly reducing quality later in the night. The best move is to treat that effect as data, not as a personality flaw. This phenotype improves when alcohol's delayed cost becomes visible instead of getting mistaken for random bad sleep.",
      ideal_next_step: "Notice the nights when alcohol changes how you sleep and use SleepSpace to support better recovery around them.",
      cta_title: "See what alcohol is doing after bedtime",
      cta_body: "Use SleepSpace to spot and reduce the sleep-quality cost when alcohol is amplifying airway strain.",
      image: "animal-boar.png"
    ),
    goose_self_snore_waker: phenotype_data(
      key: :goose_self_snore_waker,
      animal_name: "Goose",
      title: "Self-Snore Waker",
      hook: "Your own snoring may be loud enough to break the night apart.",
      description: "This profile fits people who wake from their own snoring or breathing noise. That signal matters because it suggests sleep continuity is being broken from inside the night, not just observed from outside it. The goal is to improve the stability of the night while getting clearer on the airway piece. For this phenotype, self-waking is a particularly useful clue because it shows the disruption is strong enough to pierce sleep directly.",
      ideal_next_step: "Track when your own snoring wakes you and support the rest of the sleep system while you evaluate the breathing pattern.",
      cta_title: "Reduce the wakeups caused by your own noise",
      cta_body: "SleepSpace can help improve overnight continuity while you get clearer on what snoring is doing to your sleep.",
      image: "animal-goose.png"
    ),
    moose_positional_breather: phenotype_data(
      key: :moose_positional_breather,
      animal_name: "Moose",
      title: "Positional Breather",
      hook: "Your breathing and sleep quality may change substantially with how you sleep.",
      description: "This profile fits airway-related sleep that seems clearly tied to position. Some people breathe and recover much better in one position than another, which makes this a highly actionable pattern. The goal is to use that actionability while watching for signs that more formal evaluation is still warranted. This phenotype is valuable because it gives you a concrete lever to pull while you learn more.",
      ideal_next_step: "Build a more supportive physical sleep setup and pay attention to positions that improve the night.",
      cta_title: "Turn sleep position into useful leverage",
      cta_body: "Use SleepSpace to help build steadier nights when your breathing quality depends on position.",
      image: "animal-moose.png"
    ),
    sea_lion_central_breather: phenotype_data(
      key: :sea_lion_central_breather,
      animal_name: "Sea Lion",
      title: "Central Breather",
      hook: "Your breathing-related sleep disruption may not fit the usual snoring-first pattern.",
      description: "This profile is reserved for central or atypical breathing-disruption histories where sleep feels unstable for reasons beyond classic snoring. The night may feel broken, unrefreshing, or strangely effortful without the usual clues. Naming the pattern helps keep the follow-up appropriately specific. This phenotype exists to make sure unusual breathing-related sleep concerns are not flattened into a more generic snoring story.",
      ideal_next_step: "Support the rest of the sleep system while keeping breathing-related follow-up precise and medically informed.",
      cta_title: "Support sleep while clarifying an atypical breathing pattern",
      cta_body: "SleepSpace can help improve consistency and recovery while you sort out a more complex breathing-related sleep picture.",
      image: "animal-sea-lion.png"
    ),

    seal_seasonal_adapter: phenotype_data(
      key: :seal_seasonal_adapter,
      animal_name: "Seal",
      title: "Seasonal Adapter",
      hook: "Your sleep seems to change when light, season, or environment shifts around you.",
      description: "This profile fits people whose sleep timing or quality noticeably changes with season, daylight, weather, or time-of-year routine shifts. The important takeaway is that your sleep may be more light-sensitive than average. That gives you something to work with, not just something to endure. Seasonal awareness can become a real advantage for this phenotype once you start adjusting before the shift fully lands.",
      ideal_next_step: "Use seasonal changes as a cue to adjust light exposure, bedtime rhythm, and recovery support earlier.",
      cta_title: "Adapt before the season changes your sleep for you",
      cta_body: "Use SleepSpace to make seasonal sleep changes feel more predictable and more manageable.",
      image: "animal-seal.png"
    ),
    sloth_high_sleep_need: phenotype_data(
      key: :sloth_high_sleep_need,
      animal_name: "Sloth",
      title: "High-Sleep-Need Sleeper",
      hook: "Your system may need a meaningfully larger sleep window to feel truly restored.",
      description: "This is the stronger end of the long-sleep-need spectrum. If you consistently function best with a long sleep opportunity, that matters. The key is not to pathologize the need automatically. It is to support it well and make sure the extra time is delivering real recovery. For this phenotype, honoring sleep need usually creates more stability than repeatedly trying to override it.",
      ideal_next_step: "Protect a sleep window that matches your body and make the quality inside it worth keeping.",
      cta_title: "Honor a bigger recovery need",
      cta_body: "Use SleepSpace to support longer-sleep recovery with better depth, rhythm, and consistency.",
      image: "animal-sloth.png"
    ),
    jaguar_evening_performer: phenotype_data(
      key: :jaguar_evening_performer,
      animal_name: "Jaguar",
      title: "Evening Performer",
      hook: "Your strongest performance energy may come online later than most schedules expect.",
      description: "This profile fits high performers whose best cognitive or athletic timing lands in the evening. That can be a strength, but it can also create tension with early obligations or a culture that assumes morning is always better. The right next step is to make the rhythm strategically useful instead of chronically costly. This phenotype thrives when late-day sharpness is respected without letting it quietly drain the rest of the week.",
      ideal_next_step: "Protect the strengths of a later performance curve while preventing it from turning into sleep debt.",
      cta_title: "Use late energy without paying for it all week",
      cta_body: "Use SleepSpace to make a later performance rhythm more sustainable and better aligned with recovery.",
      image: "animal-jaguar.png"
    ),
    hummingbird_micro_recovery: phenotype_data(
      key: :hummingbird_micro_recovery,
      animal_name: "Hummingbird",
      title: "Micro-Recovery Sleeper",
      hook: "Your system may be surviving on short, fragmented bursts of recovery instead of one steady night.",
      description: "This profile fits short sleep windows, fragmented nights, or a life structure that forces recovery into small pieces. It is not the same as naturally needing less sleep. It is a body trying to stay afloat on micro-recovery. The best move is to make those pieces more efficient while working toward something steadier. This phenotype is about survival-style recovery, and it benefits from every bit of structure that can make small windows count.",
      ideal_next_step: "Protect the recovery you can get now while slowly increasing rhythm and continuity where possible.",
      cta_title: "Make small windows recover more",
      cta_body: "Use SleepSpace to improve the quality of fragmented recovery when your nights come in small pieces.",
      image: "animal-hummingbird.png"
    ),
    raccoon_night_worker: phenotype_data(
      key: :raccoon_night_worker,
      animal_name: "Raccoon",
      title: "Night Worker",
      hook: "Your sleep has to recover from work that happens when most people are asleep.",
      description: "This profile is a more specific version of shift-work disruption. It fits people whose actual work hours occupy the night and force sleep into daylight or irregular margins. The challenge is not just timing. It is that your schedule repeatedly asks sleep to happen against strong biological resistance. The more protected your daytime recovery becomes, the less punishing this phenotype usually feels.",
      ideal_next_step: "Build stronger daytime sleep protection and steadier post-shift routines. SleepSpace can help create a more workable recovery system around night work.",
      cta_title: "Protect sleep after the night shift",
      cta_body: "Use SleepSpace to improve recovery when your working hours live where sleep usually belongs.",
      image: "animal-raccoon.png"
    ),
    swallow_frequent_traveler: phenotype_data(
      key: :swallow_frequent_traveler,
      animal_name: "Swallow",
      title: "Frequent-Traveler Sleeper",
      hook: "Your sleep may never fully settle before the next trip asks it to change again.",
      description: "This profile fits people who repeatedly change cities, time zones, or hotel environments quickly enough that sleep never fully re-anchors. The challenge is not one jet-lag episode. It is the accumulation of many small circadian disruptions. The best plan is portable, repeatable, and travel-aware. This phenotype improves when your travel routine carries the same recovery cues no matter where you land.",
      ideal_next_step: "Use a travel-ready sleep routine with simple anchors you can keep across locations. SleepSpace can help make that routine portable.",
      cta_title: "Keep sleep anchored while you move",
      cta_body: "Use SleepSpace to create a portable recovery system for a travel-heavy life.",
      image: "animal-swallow.png"
    ),
    vulture_grief_sleeper: phenotype_data(
      key: :vulture_grief_sleeper,
      animal_name: "Vulture",
      title: "Grief Sleeper",
      hook: "Your sleep may be carrying loss, not just fatigue.",
      description: "This profile fits people whose sleep changed in the context of grief, loss, or a major emotional rupture. Nights may feel heavy, restless, lonely, or unexpectedly wide awake. This kind of sleep disruption is not just a habit problem. It is an understandable response to a system under emotional strain. Support here works best when it honors the emotional reality instead of trying to rush the night back to normal.",
      ideal_next_step: "Start with gentleness and routine rather than force. SleepSpace can help make nights feel more supported while your system heals.",
      cta_title: "Support sleep through a harder season",
      cta_body: "Use SleepSpace to bring more steadiness and care to sleep that has been disrupted by loss.",
      image: "animal-vulture.png"
    ),
    squirrel_stress_triggered: phenotype_data(
      key: :squirrel_stress_triggered,
      animal_name: "Squirrel",
      title: "Stress-Triggered Sleeper",
      hook: "Your sleep may be mostly fine until stress flips the switch.",
      description: "This profile fits people whose sleep deteriorates quickly under acute stress, deadlines, uncertainty, or conflict. The key insight is that your sleep system seems especially responsive to trigger loads. That means prevention and early intervention matter more than late rescue. The earlier you recognize the trigger pattern, the easier it is to keep one rough night from turning into a rough week.",
      ideal_next_step: "Notice your early warning signs and deploy protective routines before sleep starts unraveling.",
      cta_title: "Catch sleep disruption closer to the trigger",
      cta_body: "Use SleepSpace to buffer the nights that are most vulnerable when life suddenly gets stressful.",
      image: "animal-squirrel.png"
    ),

    chameleon_uncertain_mixer: phenotype_data(
      key: :chameleon_uncertain_mixer,
      animal_name: "Chameleon",
      title: "Uncertain Mixer",
      hook: "Your sleep signals are real, but they are not clustering cleanly into one dominant pattern yet.",
      description: "This is the misc fallback phenotype for mixed, limited, or still-forming sleep data. You may have a flexible sleep style, a combination of smaller signals, or simply not enough recent information for one phenotype to clearly win. That is not a bad result. It just means the wisest next move is to gather a little more data and look for repeatable patterns before labeling too aggressively. Uncertainty here is part of the process, not a failure of the model or of your sleep story.",
      ideal_next_step: "Keep tracking and tighten the basics for a few more nights. SleepSpace can help you turn uncertainty into a clearer picture by improving consistency and collecting better signals.",
      cta_title: "Turn mixed signals into a clearer pattern",
      cta_body: "SleepSpace helps you move from uncertainty to a more specific sleep profile with better data and better habits.",
      image: "animal-chameleon.png",
      secondary_links: [SCIENCE_LINK]
    )
  }.freeze
end
