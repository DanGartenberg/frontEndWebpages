#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"

require_relative "./sleep_animal_service_v2"

ROOT = __dir__
OUTPUT_DIR = File.join(ROOT, "sleep-animal-pages")
PLACEHOLDER_DIR = File.join(OUTPUT_DIR, "placeholders")
ASSET_DIR = File.join(OUTPUT_DIR, "assets")

FileUtils.mkdir_p(OUTPUT_DIR)
FileUtils.mkdir_p(PLACEHOLDER_DIR)
FileUtils.mkdir_p(ASSET_DIR)

PHENOTYPES = SleepAnimalServiceV2::PHENOTYPES
GROUPS = SleepAnimalServiceV2::PHENOTYPE_GROUPS

GROUP_BY_KEY = GROUPS.each_with_object({}) do |(group, keys), memo|
  keys.each { |key| memo[key] = group }
end
GROUP_BY_KEY[:chameleon_uncertain_mixer] = :general_foundation

GROUP_META = {
  insomnia_and_fragmentation: {
    label: "Insomnia and Fragmentation",
    summary: "The dominant signal is usually difficulty initiating or maintaining sleep, plus a nervous system that remains too activated too close to bedtime.",
    axes: ["Sleep latency", "Night wakings", "Cognitive arousal", "Conditioned insomnia"],
    pitch: "This cluster works best when the page explains not only that sleep is difficult, but why generic advice often fails when the real problem is hyperarousal, stress reactivity, or a fragile transition into sleep."
  },
  circadian_and_schedule: {
    label: "Circadian and Schedule",
    summary: "These animals are often more about mistimed sleep than broken sleep. Biology, travel, work hours, and light exposure all change where the night wants to land.",
    axes: ["Chronotype", "Phase delay or advance", "Shift work", "Jet lag and social jet lag"],
    pitch: "The best long-form copy here frames late and early timing as biologic patterns that can be nudged and supported, rather than moral failures of discipline."
  },
  quantity_and_life_constraints: {
    label: "Quantity and Life Constraints",
    summary: "These animals often can sleep, but are not consistently given enough opportunity to recover because life is overbooked, interrupted, or compressed.",
    axes: ["Sleep debt", "Restricted opportunity", "Caregiving load", "Long active days"],
    pitch: "These pages should make it clear that some tired sleepers are not disordered so much as under-recovered."
  },
  airway_environment_and_physical: {
    label: "Airway, Environment, and Physical Load",
    summary: "The recurring theme here is that the body or the room keeps breaking the night apart: breathing strain, pain, heat, noise, movement, or bed-partner disruption.",
    axes: ["Physiologic load", "Snoring and breathing", "Environmental fragility", "Body discomfort"],
    pitch: "This cluster needs practical realism: some causes are behavioral, some need screening, and many overlap."
  },
  nonrestorative_and_optimization: {
    label: "Nonrestorative and Optimization",
    summary: "These animals are defined by whether the night actually delivers restoration, efficiency, and repeatable next-day readiness.",
    axes: ["Restoration", "Sleep need", "Efficiency", "Recovery quality"],
    pitch: "These pages should distinguish sleeping enough from feeling restored, while also showing how tracking can sharpen the difference."
  },
  optimum_sleepers: {
    label: "Optimum Sleepers",
    summary: "These animals describe people whose sleep already functions relatively well and who benefit most from preserving, refining, and intelligently protecting that advantage.",
    axes: ["Performance recovery", "Deep sleep", "Dream-rich sleep", "Intentional optimization"],
    pitch: "The copy here should sound like refinement, not rescue."
  },
  neuropsych_and_complex: {
    label: "Neuropsych and Complex Sleep",
    summary: "These animals often live at the edges of sleep: unstable transitions, dream enactment, vivid dream load, sleep paralysis, heavy sleep inertia, or unusual stress sensitivity.",
    axes: ["Sleep transitions", "REM-linked phenomena", "Sleep inertia", "Stress-triggered instability"],
    pitch: "The pages need to be careful, descriptive, and explicit that these are phenotype sketches rather than formal diagnoses."
  },
  special_overlap_profiles_a: {
    label: "Breathing Overlap Profiles",
    summary: "These animals combine sleep-disordered breathing with position, insomnia, alcohol, jaw tension, self-wakening, or atypical respiratory patterns.",
    axes: ["Airway overlap", "Position effects", "CPAP or oral appliance relevance", "Screening urgency"],
    pitch: "The pages should teach without sounding alarmist: enough specificity to prompt evaluation, but still readable."
  },
  special_overlap_profiles_b: {
    label: "Adaptive and Context-Sensitive Profiles",
    summary: "These animals change with season, travel, grief, late performance timing, fragmentation, or an unusually high need for sleep.",
    axes: ["Seasonality", "Portable routines", "Context-sensitive sleep", "Changing environmental demands"],
    pitch: "These pages benefit from highlighting variability and the value of multi-night tracking."
  },
  general_foundation: {
    label: "General Foundation",
    summary: "The pattern is still mixed or unclear, so the best move is to gather cleaner data and stabilize the foundation before over-labeling.",
    axes: ["Tracking quality", "Consistency", "Signal clarity", "Pattern development"],
    pitch: "This page should reassure the reader that mixed results are still useful."
  }
}.freeze

WEB_REFERENCES = {
  hyperarousal_review: {
    title: "Hyperarousal in insomnia disorder: current evidence and potential mechanisms",
    short: "Hyperarousal review",
    url: "https://pubmed.ncbi.nlm.nih.gov/37183177/",
    note: "Useful for animals defined by racing thoughts, arousal spillover, or difficulty disengaging at night."
  },
  cbti_meta: {
    title: "Cognitive behavioral therapy for insomnia: a meta-analysis of long-term effects in controlled studies",
    short: "CBT-I long-term meta-analysis",
    url: "https://pubmed.ncbi.nlm.nih.gov/31491656/",
    note: "Grounds the behavioral treatment logic behind insomnia-leaning animals."
  },
  digital_cbti: {
    title: "Comparative efficacy of digital cognitive behavioral therapy for insomnia: a systematic review and network meta-analysis",
    short: "Digital CBT-I meta-analysis",
    url: "https://pubmed.ncbi.nlm.nih.gov/34902820/",
    note: "Supports app-based behavioral support, digital programs, and scalable CBT-I framing."
  },
  stress_reactivity: {
    title: "Stress and sleep reactivity: a prospective investigation of the stress-diathesis model of insomnia",
    short: "Stress and sleep reactivity",
    url: "https://pubmed.ncbi.nlm.nih.gov/25083009/",
    note: "Useful for stress-sensitive and trigger-sensitive animals."
  },
  delayed_phase_review: {
    title: "Delayed sleep-wake phase disorder",
    short: "Delayed sleep-wake phase review",
    url: "https://pubmed.ncbi.nlm.nih.gov/29445534/",
    note: "Grounds delayed timing phenotypes in formal circadian-sleep literature."
  },
  melatonin_trial: {
    title: "Efficacy of melatonin with behavioural sleep-wake scheduling for delayed sleep-wake phase disorder",
    short: "Melatonin and scheduling trial",
    url: "https://pubmed.ncbi.nlm.nih.gov/29912983/",
    note: "Supports light, timing, and schedule-alignment language."
  },
  shift_work_review: {
    title: "Shift Work and Shift Work Sleep Disorder: Clinical and Organizational Perspectives",
    short: "Shift work review",
    url: "https://pubmed.ncbi.nlm.nih.gov/28012806/",
    note: "Useful for shift work, night work, and rotating-schedule pages."
  },
  circadian_review: {
    title: "Circadian rhythm sleep disorders: part I, basic principles, shift work and jet lag disorders",
    short: "Circadian rhythm review",
    url: "https://pubmed.ncbi.nlm.nih.gov/18041480/",
    note: "Adds broader circadian context for timing-misalignment phenotypes."
  },
  jet_lag_review: {
    title: "What works for jetlag? A systematic review of non-pharmacological interventions",
    short: "Jet lag review",
    url: "https://pubmed.ncbi.nlm.nih.gov/30529430/",
    note: "Useful for travel-heavy and jet-lag-driven animals."
  },
  sleep_deprivation_review: {
    title: "Sleep deprivation, vigilant attention, and brain function: a review",
    short: "Sleep deprivation review",
    url: "https://pubmed.ncbi.nlm.nih.gov/31176308/",
    note: "Grounds the cognitive and performance cost of chronic short sleep."
  },
  nhlbi_sleep_deprivation: {
    title: "Sleep Deprivation and Deficiency - NHLBI",
    short: "NHLBI sleep deprivation overview",
    url: "https://www.nhlbi.nih.gov/health/sleep-deprivation",
    note: "An official public-health overview of the health and daytime-function cost of insufficient sleep."
  },
  nonrestorative_sleep: {
    title: "Nonrestorative sleep",
    short: "Nonrestorative sleep review",
    url: "https://pubmed.ncbi.nlm.nih.gov/18539057/",
    note: "Useful whenever a sleeper gets enough time in bed but still wakes unrefreshed."
  },
  athlete_recovery: {
    title: "Exploring the physiological mechanisms of sleep's influence on athletic performance and recovery: a narrative review",
    short: "Athletic recovery review",
    url: "https://pubmed.ncbi.nlm.nih.gov/41217703/",
    note: "Supports performance recovery and sleep-optimization pages."
  },
  mindfulness_sleep: {
    title: "The effect of mindfulness meditation on sleep quality: a systematic review and meta-analysis of randomized controlled trials",
    short: "Mindfulness and sleep meta-analysis",
    url: "https://pubmed.ncbi.nlm.nih.gov/30575050/",
    note: "Useful for meditation, calm-down routines, and autonomic downshifting."
  },
  positional_therapy: {
    title: "Positional therapy in the management of positional obstructive sleep apnea-a review of the current literature",
    short: "Positional therapy review",
    url: "https://pubmed.ncbi.nlm.nih.gov/28852945/",
    note: "Grounds position-sensitive breathing and snoring pages."
  },
  oral_appliance: {
    title: "Oral appliance therapy in obstructive sleep apnea and snoring - systematic review and new directions of development",
    short: "Oral appliance review",
    url: "https://pubmed.ncbi.nlm.nih.gov/31588866/",
    note: "Useful for snoring-forward or airway-load phenotypes."
  },
  central_apnea_review: {
    title: "Central Sleep Apnea in Adults: An Interdisciplinary Approach to Diagnosis and Management-A Narrative Review",
    short: "Central sleep apnea review",
    url: "https://pubmed.ncbi.nlm.nih.gov/40217818/",
    note: "Useful for central or atypical breathing-disruption pages."
  },
  central_apnea_guideline: {
    title: "AASM publishes new central sleep apnea clinical practice guideline",
    short: "AASM central apnea guideline",
    url: "https://aasm.org/new-guideline-provides-treatment-recommendations-for-central-sleep-apnea/",
    note: "Official guideline summary useful for treatment-context framing."
  },
  rls_review: {
    title: "Restless Legs Syndrome: A Review",
    short: "RLS review",
    url: "https://pubmed.ncbi.nlm.nih.gov/41563785/",
    note: "Useful for movement-driven sleep disruption and leg-restlessness profiles."
  },
  noise_review: {
    title: "Environmental Noise and Effects on Sleep: An Update to the WHO Systematic Review and Meta-Analysis",
    short: "Noise and sleep review",
    url: "https://pubmed.ncbi.nlm.nih.gov/35857401/",
    note: "Grounds environmental-fragility and noise-sensitive pages."
  },
  heat_review: {
    title: "A systematic review of ambient heat and sleep in a warming climate",
    short: "Heat and sleep review",
    url: "https://pubmed.ncbi.nlm.nih.gov/38598988/",
    note: "Useful for temperature-sensitive sleepers."
  },
  pain_sleep_review: {
    title: "Chronic Pain and Sleep Disturbances: A Pragmatic Review of Their Relationships, Comorbidities, and Treatments",
    short: "Pain and sleep review",
    url: "https://pubmed.ncbi.nlm.nih.gov/31909797/",
    note: "Useful for pain-disrupted and body-load pages."
  },
  partner_review: {
    title: "Partner disturbance in co-sleeping and effects on sleep architecture: a systematic review",
    short: "Partner disturbance review",
    url: "https://pubmed.ncbi.nlm.nih.gov/41720659/",
    note: "Useful for partner-poked and shared-bed disruption pages."
  },
  sleep_paralysis_review: {
    title: "Recurrent Isolated Sleep Paralysis",
    short: "Sleep paralysis review",
    url: "https://pubmed.ncbi.nlm.nih.gov/38368058/",
    note: "Useful for sleep-paralysis and edge-of-sleep transition pages."
  },
  sleep_paralysis_features: {
    title: "Clinical features of isolated sleep paralysis",
    short: "Sleep paralysis features",
    url: "https://pubmed.ncbi.nlm.nih.gov/31141762/",
    note: "Adds clinical detail to transition-related phenomena."
  },
  rbd_review: {
    title: "REM sleep behavior disorder: Mimics and variants",
    short: "REM behavior disorder review",
    url: "https://pubmed.ncbi.nlm.nih.gov/34186416/",
    note: "Useful for dream-enactment and REM-related movement pages."
  },
  sleep_inertia: {
    title: "Sleep inertia",
    short: "Sleep inertia review",
    url: "https://pubmed.ncbi.nlm.nih.gov/12531174/",
    note: "Useful for slow-starter and heavy-grogginess pages."
  },
  grief_sleep: {
    title: "Sleep disturbances in bereavement: A systematic review",
    short: "Bereavement and sleep review",
    url: "https://pubmed.ncbi.nlm.nih.gov/32505968/",
    note: "Useful for loss-related or grief-sensitive sleep disruption."
  },
  seasonal_sleep: {
    title: "Chronotype and sleep duration: the influence of season of assessment",
    short: "Seasonality and chronotype study",
    url: "https://pubmed.ncbi.nlm.nih.gov/24679223/",
    note: "Useful for seasonal-adapter and light-sensitive timing pages."
  }
}.freeze

LIBRARY_REFERENCES = {
  digital_cbti_outcomes: {
    title: "Sleep-specific outcomes attributable to digitally delivered cognitive behavioral therapy for insomnia in adults with insomnia and depressive symptoms",
    short: "Digital CBT-I sleep outcomes",
    filename: "Sleep-specific outcomes attributable to digitally delivered cognitive behavioral therapy for insomnia in adults with insomnia and depressive symptoms.pdf",
    summary: "Supports the idea that targeted behavioral insomnia treatment can improve more than a vague sense of sleep quality, including concrete sleep outcomes.",
    groups: %i[insomnia_and_fragmentation]
  },
  somryst_profile: {
    title: "Profile of Somryst Prescription Digital Therapeutic for Chronic Insomnia: Overview of Safety and Efficacy",
    short: "Somryst insomnia therapeutic profile",
    filename: "Profile of Somryst Prescription Digital Therapeutic for Chronic Insomnia Overview of Safety and Efficacy.pdf",
    summary: "Useful for insomnia pages that discuss structured behavioral treatment rather than purely generic sleep hygiene.",
    groups: %i[insomnia_and_fragmentation]
  },
  dream_protocol: {
    title: "Protocol for digital real-world evidence trial for adults with insomnia treated via mobile (DREAM)",
    short: "DREAM insomnia mobile protocol",
    filename: "thorndike-et-al-2021-protocol-for-digital-real-world-evidence-trial-for-adults-with-insomnia-treated-via-mobile-(dream).pdf",
    summary: "Relevant when explaining how mobile sleep interventions can be studied in real-world adult insomnia populations.",
    groups: %i[insomnia_and_fragmentation]
  },
  cbti_cognition: {
    title: "Does cognitive behavioural therapy for insomnia improve cognitive performance?",
    short: "CBT-I and cognition",
    filename: "Does+cognitive+behavioural+therapy+for+insomnia+improve+cognitive+performance+AAM.pdf",
    summary: "Helpful for pages that describe insomnia as a next-day focus and cognitive burden rather than only a nighttime complaint.",
    groups: %i[insomnia_and_fragmentation nonrestorative_and_optimization]
  },
  ereader_circadian: {
    title: "Evening use of light-emitting eReaders negatively affects sleep, circadian timing, and next-morning alertness",
    short: "Evening light and circadian timing",
    filename: "chang-et-al-2014-evening-use-of-light-emitting-ereaders-negatively-affects-sleep-circadian-timing-and-next-morning.pdf",
    summary: "Useful for late-timing, delayed-clock, and schedule-misalignment pages because it connects evening light exposure to circadian delay and morning impairment.",
    groups: %i[circadian_and_schedule]
  },
  sleep_recommendation: {
    title: "Grandner-style sleep duration recommendation resource",
    short: "Sleep duration recommendations",
    filename: "grandnerRecommendationSleep-30-5-635.pdf",
    summary: "Useful for pages centered on insufficient sleep opportunity, sleep debt, and quantity as the main problem.",
    groups: %i[quantity_and_life_constraints special_overlap_profiles_b]
  },
  wearables_science: {
    title: "State of the Science and Recommendations for Wearables in Sleep and Circadian Research",
    short: "Wearables recommendations",
    filename: "de Zambotti M et al (2024)_State of the Science and Recommendations for Wearables in SC Research.pdf",
    summary: "Useful for tracking sections that explain what wearables can and cannot clarify about a pattern over time.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers special_overlap_profiles_b general_foundation]
  },
  sleep_apnea_sonar: {
    title: "Detection of Sleep Apnea Using Sonar Smartphone Technology",
    short: "Smartphone apnea detection",
    filename: "Detection_of_Sleep_Apnea_Using_Sonar_Smartphone_Technology.pdf",
    summary: "Helpful for snoring, apnea-screening, and remote monitoring pages.",
    groups: %i[airway_environment_and_physical special_overlap_profiles_a]
  },
  predict_osa_photo: {
    title: "Prediction of obstructive sleep apnea with craniofacial photographic analysis",
    short: "OSA craniofacial photo analysis",
    filename: "sleep-32-1-46.pdf",
    summary: "Useful for airway phenotypes that discuss anatomy-driven risk and phenotype variation.",
    url: "https://researchers.mq.edu.au/en/publications/prediction-of-obstructive-sleep-apnea-with-craniofacial-photograp/",
    groups: %i[airway_environment_and_physical special_overlap_profiles_a]
  },
  predict_osa_3d: {
    title: "Predicting sleep apnea from three-dimensional face photography",
    short: "3D face photography for OSA",
    filename: "jcsm.16.4.493.pdf",
    summary: "Useful for pages explaining that airway phenotypes can look anatomically distinct rather than behaviorally identical.",
    url: "https://ro.ecu.edu.au/ecuworkspost2013/8460/",
    groups: %i[airway_environment_and_physical special_overlap_profiles_a]
  },
  stopbang_mortality: {
    title: "STOP-Bang and cardiovascular mortality resource",
    short: "STOP-Bang mortality resource",
    filename: "stopBangCardiovascularMortality.pdf",
    summary: "Supports the medical importance of screening-heavy breathing phenotypes.",
    groups: %i[special_overlap_profiles_a]
  },
  osa_hypertension: {
    title: "The Association Between Obstructive Sleep Apnea and Hypertension",
    short: "OSA and hypertension",
    filename: "J of Clinical Hypertension - 2013 - Sands‐Lincoln - The Association Between Obstructive Sleep Apnea and Hypertension by.pdf",
    summary: "Useful for pages where snoring and apnea clues are framed as cardiovascular as well as sleep issues.",
    groups: %i[special_overlap_profiles_a]
  },
  cpap_adherence: {
    title: "Relationship between hours of CPAP use and achieving normal levels of sleepiness and daily functioning",
    short: "CPAP dose-response",
    filename: "sleep-30-6-711.pdf",
    summary: "Useful for overlap pages that discuss why adherence and nightly use matter.",
    url: "https://www.researchgate.net/publication/6255858_Relationship_between_hours_of_CPAP_use_and_achieving_normal_levels_of_sleepiness_and_treatment",
    groups: %i[special_overlap_profiles_a]
  },
  mad_mouth_closing: {
    title: "Mouth closing to improve the efficacy of mandibular advancement devices in sleep apnea",
    short: "Mouth closing with MADs",
    filename: "labarca-et-al-2022-mouth-closing-to-improve-the-efficacy-of-mandibular-advancement-devices-in-sleep-apnea.pdf",
    summary: "Useful for appliance-forward breathing pages and practical airway-support discussions.",
    groups: %i[special_overlap_profiles_a]
  },
  noise_performance: {
    title: "Noise improves ADHD performance",
    short: "Noise and performance context",
    filename: "Soderlund_Sikstrom_Smart_2007_Noise_Improves_ADHD_performance_J_Child_Psy_Psy.pdf",
    summary: "Included more cautiously as a reminder that sound is not purely harmful in all contexts, even though nighttime sleep fragmentation from noise is usually counterproductive.",
    groups: %i[airway_environment_and_physical]
  },
  acoustic_stimulation: {
    title: "Enhancing slow oscillations and increasing N3 sleep proportion",
    short: "Acoustic deep-sleep stimulation",
    filename: "nss-243204-enhancing-slow-oscillations-and-increasing-n3-sleep-proporti.pdf",
    summary: "Useful for optimization pages focused on deep sleep enhancement and restorative architecture.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers]
  },
  modius_study: {
    title: "Brain Stimulation Modius Sleep Study",
    short: "Modius sleep study",
    filename: "Brain Stimulation Modius Sleep Study.pdf",
    summary: "Useful for performance and optimization sections where neuromodulation or advanced sleep-support technology is mentioned as experimental context.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers]
  },
  boosting_recovery: {
    title: "Boosting Recovery During Sleep by Means of External Stimulation",
    short: "Boosting recovery during sleep",
    filename: "Boosting_Recovery_During_Sleep_by_Means.pdf",
    summary: "Helpful for high-performance and recovery-oriented animals where sleep is treated as an active training resource.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers]
  },
  targeted_memory_reactivation: {
    title: "Upgrading the sleeping brain with targeted memory reactivation",
    short: "Targeted memory reactivation",
    filename: "Upgrading the sleeping brain with targeted memory reactivation.pdf",
    summary: "Useful for dream, memory, and optimization pages, especially when the sleeper is curious about how nighttime brain activity affects next-day cognition.",
    groups: %i[optimum_sleepers neuropsych_and_complex]
  },
  rem_sws_brain_atrophy: {
    title: "Lower slow-wave sleep and REM sleep are associated with brain atrophy of AD-vulnerable regions",
    short: "Slow-wave and REM with brain atrophy",
    filename: "cho-et-al-2025-lower-slow-wave-sleep-and-rapid-eye-movement-sleep-are-associated-with-brain-atrophy-of-ad-vulnerable.pdf",
    summary: "Useful for pages that discuss why architecture quality matters beyond simply time in bed.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers neuropsych_and_complex]
  },
  wearables_image: {
    title: "SleepSpaceWithWearables visual",
    short: "SleepSpace wearables visual",
    filename: "SleepSpaceWithWearables.png",
    summary: "Useful as an explanatory visual for the tracking sections that discuss phone-based sensing plus wearable integrations.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers special_overlap_profiles_b general_foundation]
  }
}.freeze

EXTRA_LIBRARY_REFERENCES = {
  sleepspace_validation_insomnia: {
    title: "SleepSpace validation for insomnia",
    short: "SleepSpace insomnia validation",
    filename: "sleepSpaceValidationForInsomnia.docx",
    summary: "Useful for insomnia-forward pages that connect phenotype interpretation to SleepSpace-specific validation and insomnia assessment work.",
    groups: %i[insomnia_and_fragmentation nonrestorative_and_optimization general_foundation]
  },
  sleepspace_bsm_submission: {
    title: "Behavioral Sleep Medicine submission proof",
    short: "BSM submission proof",
    filename: "BSM Submission Proof 20250730.pdf",
    summary: "Useful for pages that frame SleepSpace as a behaviorally grounded sleep intervention platform rather than only a generic tracker.",
    groups: %i[insomnia_and_fragmentation nonrestorative_and_optimization general_foundation]
  },
  sleepspace_ms_draft: {
    title: "Restructured manuscript draft",
    short: "SleepSpace manuscript draft",
    filename: "Restructured MS draft 2024_08_27.docx",
    summary: "Useful as local manuscript context for pages that emphasize measurement, intervention framing, and phenotype interpretation.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  sleepspace_protocol_slides: {
    title: "Protocol for publication slides",
    short: "Protocol publication slides",
    filename: "Protocol for pub.pptx",
    summary: "Useful for pages that describe implementation logic, measurement strategy, and intervention structure.",
    groups: %i[insomnia_and_fragmentation general_foundation]
  },
  sleepspace_poster_final: {
    title: "SleepSpace poster final",
    short: "SleepSpace poster final",
    filename: "Poster 20240528 final (1).pdf",
    summary: "Useful for general evidence framing and for pages that discuss wearable-based sleep-wake classification or validation work.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  sleepspace_aacsm: {
    title: "AACSM sleep publication",
    short: "AACSM publication",
    filename: "aacsm.pdf",
    summary: "Useful for general scientific support on pages that discuss digital sleep measurement and SleepSpace research context.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  sleepspace_actigraphy_session: {
    title: "Actigraphy Sleep Health session",
    short: "Actigraphy session",
    filename: "Actigraphy Sleep Health Session v5_12_20_2021.docx",
    summary: "Useful for pages that emphasize actigraphy, sleep timing, sleep opportunity, and practical interpretation of longitudinal sleep data.",
    groups: %i[circadian_and_schedule quantity_and_life_constraints general_foundation]
  },
  sleepspace_ubiquitous_computing: {
    title: "Ubiquitous computing paper",
    short: "Ubiquitous computing and sleep sensing",
    filename: "ubiquitous_computing_paper_12.pdf",
    summary: "Useful for pages that explain ambient sensing, digital phenotyping, and consumer-device-based sleep measurement.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  actigraphy_cole_richards: {
    title: "Cole and Richards nursing overview on actigraphy and sleep assessment",
    short: "Cole and Richards actigraphy overview",
    filename: "2007 Cole & Richards Am J Nurs {26960}.pdf",
    summary: "Useful for pages that explain actigraphy, diary interpretation, and real-world sleep measurement outside the lab.",
    groups: %i[general_foundation quantity_and_life_constraints]
  },
  actigraphy_sadeh_review: {
    title: "Sadeh review on the role and limitations of actigraphy in sleep medicine",
    short: "Sadeh actigraphy review",
    filename: "2010 Sadeh Sleep Med Rev {26945}.pdf",
    summary: "Useful for any page that distinguishes wearable trends from formal sleep diagnostics.",
    groups: %i[general_foundation circadian_and_schedule quantity_and_life_constraints]
  },
  circadian_shoji: {
    title: "Shoji et al. Sleep Science",
    short: "Shoji circadian context",
    filename: "2015 Shoji et al. Sleep Sci {26961}.pdf",
    summary: "Useful for pages about sleep timing, circadian preference, and schedule alignment.",
    groups: %i[circadian_and_schedule special_overlap_profiles_b]
  },
  circadian_sekine: {
    title: "Sekine et al. Sleep Medicine",
    short: "Sekine sleep timing paper",
    filename: "2014 Sekine et al. Sleep Med {26958}.pdf",
    summary: "Useful for circadian and schedule pages that discuss timing mismatch and sleep regularity.",
    groups: %i[circadian_and_schedule special_overlap_profiles_b]
  },
  work_sleep_germeys: {
    title: "Germeys and Leineweber on sleep and work-related recovery",
    short: "Work recovery and sleep",
    filename: "2019 Germeys & Leineweber Sleep {26956}.pdf",
    summary: "Useful for work-constrained, commuter, and overload phenotypes where sleep loss spills into performance and recovery.",
    groups: %i[quantity_and_life_constraints special_overlap_profiles_b]
  },
  work_sleep_crain: {
    title: "Crain, Brossoit, and Fisher on sleep and workplace psychology",
    short: "Workplace sleep psychology",
    filename: "2018 Crain, Brossoit, & Fisher J Bus Psychol {.pdf",
    summary: "Useful for pages centered on work stress, constrained sleep opportunity, and recovery boundaries.",
    groups: %i[quantity_and_life_constraints insomnia_and_fragmentation]
  },
  public_health_grandner: {
    title: "Grandner et al. sleep health framework",
    short: "Sleep health framework",
    filename: "2016 Grandner et al {26860}.pdf",
    summary: "Useful across pages that frame sleep as a multidimensional health construct rather than just time in bed.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization general_foundation]
  },
  sleep_health_jackson: {
    title: "Jackson et al. Sleep",
    short: "Sleep and population health",
    filename: "2018 Jackson et al. Sleep {26936}.pdf",
    summary: "Useful for pages that connect sleep phenotypes to broader functioning, health disparities, and social context.",
    groups: %i[quantity_and_life_constraints general_foundation]
  },
  lifestyle_kline: {
    title: "Kline on sleep as a lifestyle behavior",
    short: "Sleep as lifestyle behavior",
    filename: "2014 Kline Am J Lifestyle Med {26933}.pdf",
    summary: "Useful for pages that explain sleep as a trainable health behavior influenced by exercise, routines, and daily structure.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization]
  },
  student_sleep_hershner_clin: {
    title: "Hershner and O'Brien on sleep in college students",
    short: "College sleep review",
    filename: "2018 Hershner & O'Brien J Clin Sleep Med {2692.pdf",
    summary: "Useful for late-schedule, irregular-routine, and under-slept young-adult pages.",
    groups: %i[circadian_and_schedule quantity_and_life_constraints]
  },
  student_sleep_hershner_nat: {
    title: "Hershner and Chervin on causes and consequences of sleepiness in college students",
    short: "College sleepiness review",
    filename: "2014 Hershner & Chervin Nat Sci Sleep {26908}.pdf",
    summary: "Useful for pages involving social jet lag, irregular scheduling, and chronic next-day sleepiness in younger adults.",
    groups: %i[circadian_and_schedule quantity_and_life_constraints]
  },
  student_sleep_kelly: {
    title: "Kelly, Kelly, and Clanton on sleep habits in college students",
    short: "College sleep habits",
    filename: "2001 Kelly, Kelly, and Clanton Coll Stud J {26.pdf",
    summary: "Useful for pages that describe voluntary sleep restriction, academic pressure, and uneven weekday-weekend patterns.",
    groups: %i[quantity_and_life_constraints circadian_and_schedule]
  },
  shift_work_kubo: {
    title: "Kubo et al. Industrial Health on shift-related sleep burden",
    short: "Shift-work burden",
    filename: "2017 Kubo et al. Ind Health {26762}.pdf",
    summary: "Useful for shift-worker, rotating-schedule, and circadian-misalignment pages.",
    groups: %i[circadian_and_schedule special_overlap_profiles_b]
  },
  circadian_vitale: {
    title: "Vitale et al. Chronobiology International",
    short: "Chronobiology and performance timing",
    filename: "2014 Vitale et al. Chronobiol Int {25701}.pdf",
    summary: "Useful for pages that connect circadian timing with performance, schedule timing, and biologic readiness.",
    groups: %i[circadian_and_schedule optimum_sleepers]
  },
  immune_sleep_besedovsky: {
    title: "Besedovsky et al. Nature Communications on sleep and immune function",
    short: "Sleep and immune function",
    filename: "2017 Besedovsky et al. Nat Commun {26808}.pdf",
    summary: "Useful for pages that frame sleep as a recovery system with biologic consequences beyond subjective energy.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers]
  },
  memory_ngo: {
    title: "Ngo et al. Neuron on acoustic stimulation and slow oscillations",
    short: "Slow oscillation stimulation",
    filename: "2013 Ngo et al. Neuron {26793}.pdf",
    summary: "Useful for architecture and optimization pages that discuss slow waves, memory processing, and deep-sleep enhancement.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers neuropsych_and_complex]
  },
  memory_ladenbauer: {
    title: "Ladenbauer et al. NeuroImage on sleep stimulation and memory",
    short: "Sleep stimulation and memory",
    filename: "2016 Ladenbauer et al. Neuroimage {26769}.pdf",
    summary: "Useful for pages about restoration, memory consolidation, and architecture-focused intervention ideas.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers neuropsych_and_complex]
  },
  memory_lafortune: {
    title: "Lafortune et al. Journal of Sleep Research",
    short: "Sleep architecture and aging",
    filename: "2014 Lafortune et al. J Sleep Res {26789}.pdf",
    summary: "Useful for pages that discuss sleep architecture, brain aging, and why deep sleep quality matters.",
    groups: %i[nonrestorative_and_optimization neuropsych_and_complex]
  },
  synaptic_tononi: {
    title: "Tononi et al. on sleep and synaptic homeostasis",
    short: "Synaptic homeostasis context",
    filename: "2010 Tononi et al. Medicamundi {26959}.pdf",
    summary: "Useful for pages that describe sleep as a biologic reset process rather than simple inactivity.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers]
  },
  memory_pace_schott: {
    title: "Pace-Schott and Spencer on sleep-dependent memory processing",
    short: "Sleep and memory processing",
    filename: "2014 Pace-Schott & Spencer Curr Topics Behav N.pdf",
    summary: "Useful for pages involving dream-rich sleep, cognition, and next-day learning or emotional processing.",
    groups: %i[optimum_sleepers neuropsych_and_complex]
  },
  aging_scullin_bliwise: {
    title: "Scullin and Bliwise on sleep, cognition, and aging",
    short: "Sleep, aging, and cognition",
    filename: "2015 Scullin & Bliwise Sleep {25552}.pdf",
    summary: "Useful for pages that discuss restoration, cognition, and age-linked changes in sleep architecture.",
    groups: %i[nonrestorative_and_optimization neuropsych_and_complex]
  },
  metabolism_bianchi: {
    title: "Bianchi on sleep and metabolism",
    short: "Sleep and metabolism context",
    filename: "2018 Bianchi Metabolism {26839}.pdf",
    summary: "Useful for pages that connect under-recovery with metabolic strain and whole-body health effects.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization]
  },
  metabolism_swanson: {
    title: "Swanson et al. on sleep and metabolic health",
    short: "Sleep and metabolic health",
    filename: "2018 Swanson et al Metabolism {25798}.pdf",
    summary: "Useful for pages that emphasize that insufficient or poor-quality sleep has downstream metabolic costs.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization]
  },
  metabolism_buxton: {
    title: "Buxton et al. on sleep restriction and metabolic dysfunction",
    short: "Sleep restriction and metabolism",
    filename: "2010 Buxton et al. Diabetes {25793}.pdf",
    summary: "Useful for quantity-constrained pages that need stronger physiologic support for chronic under-recovery.",
    groups: %i[quantity_and_life_constraints]
  },
  mental_health_tsuno: {
    title: "Tsuno et al. on sleep and psychiatric burden",
    short: "Sleep and mental health review",
    filename: "2005 Tsuno et al. J Clin Psychiatry {25694}.pdf",
    summary: "Useful for insomnia, stress-triggered, and emotionally loaded sleep phenotypes.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  insomnia_linton: {
    title: "Linton et al. Sleep Medicine Reviews on insomnia and mental health",
    short: "Insomnia and mental health",
    filename: "2015 Linton et al. Sleep Med Rev {26731}.pdf",
    summary: "Useful for pages where insomnia, stress sensitivity, and next-day emotional burden overlap.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  anxiety_alfano: {
    title: "Alfano et al. on sleep and anxiety in youth",
    short: "Sleep and anxiety context",
    filename: "2010 Alfano et al. Child Psychiatry Hum Dev {2.pdf",
    summary: "Useful for pages that describe stress-triggered or anticipatory sleep difficulty.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  adhd_becker: {
    title: "Becker et al. Sleep Medicine Reviews on ADHD and sleep",
    short: "ADHD and sleep review",
    filename: "2017 Becker et al. Sleep Med Rev {26944}.pdf",
    summary: "Useful for pages involving arousal regulation, attention burden, irregular sleep timing, and stress-triggered sleep disruption.",
    groups: %i[insomnia_and_fragmentation circadian_and_schedule neuropsych_and_complex]
  },
  population_sleep_fox: {
    title: "Fox et al. Sleep Health",
    short: "Population sleep health",
    filename: "2018 Fox et al. Sleep Health {26705}.pdf",
    summary: "Useful for pages that frame sleep phenotypes inside broader health behavior and public-health context.",
    groups: %i[quantity_and_life_constraints general_foundation]
  },
  population_sleep_full: {
    title: "Full et al. Sleep Health",
    short: "Sleep health patterns",
    filename: "2018 Full et al Sleep Health {25357}.pdf",
    summary: "Useful for under-slept, socially constrained, and lifestyle-driven sleep pages.",
    groups: %i[quantity_and_life_constraints general_foundation]
  },
  measurement_van_hees: {
    title: "van Hees et al. Scientific Reports on wearable or actigraphy estimation",
    short: "Wearable sleep estimation",
    filename: "2018 van Hees et al Sci Rep {25800}.pdf",
    summary: "Useful for pages that discuss how movement-based wearables infer sleep and wake over multiple nights.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  measurement_agreement: {
    title: "Agreement of different methods for sleep assessment",
    short: "Agreement across sleep measures",
    filename: "Agreement_of_different_methods_for_asses.pdf",
    summary: "Useful for pages that compare diaries, wearables, actigraphy, and other consumer or clinical measurement approaches.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  sleep_evolution: {
    title: "Sleep evolution",
    short: "Sleep evolution context",
    filename: "Sleep Evolution.pdf",
    summary: "Useful as broad conceptual context on why human sleep shows recurring adaptive patterns rather than a single ideal night for everyone.",
    groups: %i[general_foundation special_overlap_profiles_b]
  }
}.freeze

EXTRA_LIBRARY_REFERENCES_2 = {
  psqi_buysse: {
    title: "Buysse et al. Pittsburgh Sleep Quality Index",
    short: "PSQI foundational paper",
    filename: "Buysse et al., 1989.pdf",
    summary: "Useful for pages that reference sleep quality as a multidimensional construct and for framing self-report sleep assessment.",
    groups: %i[general_foundation insomnia_and_fragmentation nonrestorative_and_optimization]
  },
  hasler_circadian_affect: {
    title: "Hasler et al. on circadian timing and affective risk",
    short: "Circadian timing and affect",
    filename: "Hasler et al., 2014.pdf",
    summary: "Useful for delayed-clock, mood-linked, and stress-sensitive pages where timing and emotional regulation overlap.",
    groups: %i[circadian_and_schedule insomnia_and_fragmentation neuropsych_and_complex]
  },
  kwv251_circadian: {
    title: "kwv251 circadian publication",
    short: "Circadian publication",
    filename: "kwv251.pdf",
    summary: "Useful for circadian, chronotype, and schedule-misalignment pages.",
    groups: %i[circadian_and_schedule special_overlap_profiles_b]
  },
  sleep_deprived_human_brain: {
    title: "Sleep-Deprived Human Brain",
    short: "Sleep-deprived brain review",
    filename: "Sleep-Deprived Human Brain.pdf",
    summary: "Useful for pages that explain cognitive slowing, emotional lability, and performance degradation under sleep loss.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization neuropsych_and_complex]
  },
  marino_measurement_accuracy: {
    title: "Marino et al. measuring sleep accuracy and sensitivity",
    short: "Sleep measurement accuracy",
    filename: "Marino-2013-Measuring sleep_ accuracy, sensiti.pdf",
    summary: "Useful for pages that discuss consumer-wearable or actigraphy accuracy versus more formal sleep assessment.",
    groups: %i[general_foundation nonrestorative_and_optimization circadian_and_schedule]
  },
  thomas_sleepiness_2000: {
    title: "Thomas et al. 2000 on sleepiness and neurobehavioral burden",
    short: "Sleepiness and neurobehavior",
    filename: "Thomas et al., 2000.pdf",
    summary: "Useful for under-recovery and sleep-debt pages that need stronger grounding in next-day cognitive cost.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization]
  },
  fichtenberg_insomnia_neuropsych: {
    title: "Fichtenberg et al. 2001 on insomnia and neuropsychological function",
    short: "Insomnia and neuropsych function",
    filename: "Fichtenberg et al., 2001.pdf",
    summary: "Useful for pages where insomnia is described as a cognitive and daytime-function burden.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  wong_sleep_measurement_2011: {
    title: "Wong et al. 2011 sleep measurement paper",
    short: "Sleep measurement 2011",
    filename: "Wong et al., 2011.pdf",
    summary: "Useful for pages that compare sleep tracking approaches and discuss measurement quality.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  wong_sleep_measurement_2015: {
    title: "Wong et al. 2015 sleep measurement paper",
    short: "Sleep measurement 2015",
    filename: "Wong et al., 2015.pdf",
    summary: "Useful for pages emphasizing digital phenotyping, repeat measurement, and sleep assessment fidelity.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  wong_sleep_measurement_2016: {
    title: "Wong et al. 2016 sleep measurement paper",
    short: "Sleep measurement 2016",
    filename: "Wong et al., 2016.pdf",
    summary: "Useful for pages where wearable validity and interpretation limitations matter.",
    groups: %i[general_foundation nonrestorative_and_optimization]
  },
  thomas_2015_sleep_loss: {
    title: "Thomas et al. 2015 on sleep loss and brain function",
    short: "Sleep loss and brain function",
    filename: "Thomas et al., 2015.pdf",
    summary: "Useful for fatigue, overload, and nonrestorative pages that discuss attention, executive function, and neural cost.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization neuropsych_and_complex]
  },
  womack_shift_performance: {
    title: "Womack et al. 2013 on shift-related fatigue and performance",
    short: "Shift performance paper",
    filename: "Womack et al., 2013.pdf",
    summary: "Useful for shift-work and circadian-mismatch pages that link timing disruption with performance cost.",
    groups: %i[circadian_and_schedule special_overlap_profiles_b]
  },
  tavernier_sleep_alcohol: {
    title: "Tavernier et al. 2015 on sleep and alcohol-related behavior",
    short: "Sleep and alcohol context",
    filename: "Tavernier et al., 2015.pdf",
    summary: "Useful for overlap pages where alcohol, schedule drift, and fragmented recovery intersect.",
    groups: %i[special_overlap_profiles_a special_overlap_profiles_b quantity_and_life_constraints]
  },
  terry_mcelrath_adolescent_sleep: {
    title: "Terry-McElrath et al. 2016 adolescent sleep paper",
    short: "Adolescent sleep patterns",
    filename: "Terry-McElrath et al., 2016.pdf",
    summary: "Useful for pages involving younger sleepers, social jet lag, inconsistent routines, and school-driven sleep loss.",
    groups: %i[circadian_and_schedule quantity_and_life_constraints]
  },
  pieters_sleep_affect: {
    title: "Pieters et al. 2015 on sleep and emotional or health outcomes",
    short: "Sleep and emotional health",
    filename: "Pieters et al., 2015.pdf",
    summary: "Useful for stress-sensitive and insomnia-forward pages where next-day emotional burden is part of the phenotype.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  sagaspe_sleepiness_performance: {
    title: "Sagaspe et al. 2012 on sleepiness and performance impairment",
    short: "Sleepiness and performance impairment",
    filename: "Sagaspe et al., 2012.PDF",
    summary: "Useful for pages describing vigilance lapses, commuting fatigue, and performance-sensitive sleep loss.",
    groups: %i[quantity_and_life_constraints circadian_and_schedule]
  },
  mcglinchey_harvey_insomnia: {
    title: "McGlinchey and Harvey 2015 insomnia publication",
    short: "Insomnia process paper",
    filename: "McGlinchey & Harvey, 2015.pdf",
    summary: "Useful for insomnia pages that discuss perpetuating cognitive and behavioral mechanisms.",
    groups: %i[insomnia_and_fragmentation]
  },
  daly_work_sleep: {
    title: "Daly et al. 2015 on work and sleep strain",
    short: "Work strain and sleep",
    filename: "Daly et al., 2015.pdf",
    summary: "Useful for workload, overtime, and commuter phenotypes.",
    groups: %i[quantity_and_life_constraints]
  },
  edwards_work_sleep: {
    title: "Edwards et al. 2015 on sleep and work functioning",
    short: "Sleep and work functioning",
    filename: "Edwards et al., 2015.pdf",
    summary: "Useful for pages where sleep loss translates into workplace performance and self-regulation cost.",
    groups: %i[quantity_and_life_constraints]
  },
  rosekind_fatigue_work: {
    title: "Rosekind et al. occupational fatigue paper",
    short: "Occupational fatigue",
    filename: "2010 Rosekind et al J Occup Environ Med {25602.pdf",
    summary: "Useful for pages about professional fatigue, commuting risk, and chronic under-recovery at work.",
    groups: %i[quantity_and_life_constraints special_overlap_profiles_b]
  },
  friborg_sleep_quality: {
    title: "Friborg et al. Journal of Sleep Research",
    short: "Sleep quality and distress",
    filename: "2012 Friborg et al J Sleep Res {25600}.pdf",
    summary: "Useful for insomnia and nonrestorative pages that discuss sleep quality and psychological distress together.",
    groups: %i[insomnia_and_fragmentation nonrestorative_and_optimization]
  },
  passos_exercise_sleep: {
    title: "Passos et al. Clinics on exercise and sleep",
    short: "Exercise and sleep",
    filename: "2012 Passos et al Clinics {25596}.pdf",
    summary: "Useful for pages that discuss exercise as a practical lever for restoration and sleep quality.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers quantity_and_life_constraints]
  },
  driver_taylor_exercise: {
    title: "Driver and Taylor on exercise and sleep",
    short: "Exercise-sleep review",
    filename: "2000 Driver & Taylor Sleep Med Rev {12921}.pdf",
    summary: "Useful for pages linking daytime movement, fitness, and nighttime recovery.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers]
  },
  youngstedt_exercise_sleep: {
    title: "Youngstedt on exercise and sleep",
    short: "Exercise timing and sleep",
    filename: "2005 Youngstedt Clin Sports Med {25588}.pdf",
    summary: "Useful for pages about athletic recovery, activation, and how exercise can help or shift sleep.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers circadian_and_schedule]
  },
  alvaro_sleep_depression: {
    title: "Alvaro et al. Sleep Medicine on sleep and depression",
    short: "Sleep and depression review",
    filename: "2014 Alvaro et al Sleep Med {25584}.pdf",
    summary: "Useful for pages where low mood, insomnia, and nonrestorative sleep overlap.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  cain_gradisar_adolescent: {
    title: "Cain and Gradisar on electronic media and adolescent sleep",
    short: "Adolescent sleep timing review",
    filename: "2010 Cain & Gradisar Sleep Med {25578}.pdf",
    summary: "Useful for delayed-clock, night-owl, and younger-sleeper pages involving late light exposure and schedule drift.",
    groups: %i[circadian_and_schedule quantity_and_life_constraints]
  },
  roberts_behav_sleep_med: {
    title: "Roberts et al. Behavioral Sleep Medicine",
    short: "Behavioral sleep patterns",
    filename: "2011 Roberts et al Behav Sleep Med {25577}.pdf",
    summary: "Useful for pages that frame sleep as shaped by repeatable habits and behavioral routines.",
    groups: %i[insomnia_and_fragmentation quantity_and_life_constraints general_foundation]
  },
  haimov_insomnia_older: {
    title: "Haimov et al. on insomnia in older adults",
    short: "Older-adult insomnia",
    filename: "2008 Haimov et al Behav Sleep Med {25559}.pdf",
    summary: "Useful for pages involving maintenance insomnia, early waking, and age-related sleep complaints.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  cricco_older_adults: {
    title: "Cricco et al. on insomnia prevalence in older adults",
    short: "Older adult insomnia prevalence",
    filename: "2001 Cricco et al J Am Geriat Soc {25557}.pdf",
    summary: "Useful for age-sensitive pages and general prevalence context around insomnia complaints.",
    groups: %i[insomnia_and_fragmentation general_foundation]
  },
  oosterman_sleep_cognition: {
    title: "Oosterman et al. on sleep and cognition",
    short: "Sleep and cognition",
    filename: "2009 Oosterman et al J Sleep Res {25549}.pdf",
    summary: "Useful for pages where poor sleep is described as reduced cognitive clarity and daytime mental efficiency.",
    groups: %i[nonrestorative_and_optimization neuropsych_and_complex]
  },
  zhang_pnas_sleep_deprivation: {
    title: "Zhang et al. PNAS on sleep deprivation biology",
    short: "Sleep deprivation biology",
    filename: "2014 Zhang et al PNAS {25532}.pdf",
    summary: "Useful for pages emphasizing that sleep loss changes biology, not just mood or motivation.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization]
  },
  roth_insomnia_daytime: {
    title: "Roth et al. Sleep on daytime impact of insomnia",
    short: "Insomnia daytime burden",
    filename: "2018 Roth et al Sleep {25520}.pdf",
    summary: "Useful for pages that explain insomnia as a 24-hour disorder with daytime impairment.",
    groups: %i[insomnia_and_fragmentation]
  },
  akerstedt_work_recovery: {
    title: "Akerstedt et al. on work stress and disturbed sleep",
    short: "Work stress and sleep",
    filename: "2012 Akerstedt et al Sleep Medicine {25509}.pdf",
    summary: "Useful for work-stress, overload, and commuter phenotypes.",
    groups: %i[quantity_and_life_constraints insomnia_and_fragmentation]
  },
  bauer_bipolar_circadian: {
    title: "Bauer et al. Bipolar Disorders on circadian instability",
    short: "Circadian instability and bipolarity",
    filename: "2006 Bauer et al Bipolar Disorders {25502}.pdf",
    summary: "Useful for pages where sleep timing instability and mood-linked sleep disruption intersect.",
    groups: %i[circadian_and_schedule neuropsych_and_complex]
  },
  grandner_jcsm_sleep_health: {
    title: "Grandner et al. JCSM on sleep health dimensions",
    short: "Sleep health dimensions",
    filename: "2013 Grandner et al JCSM {25482}.pdf",
    summary: "Useful for general foundation pages and for framing phenotypes across duration, continuity, timing, alertness, and satisfaction.",
    groups: %i[general_foundation nonrestorative_and_optimization quantity_and_life_constraints]
  },
  kalmbach_sleep_reactivity: {
    title: "Kalmbach et al. on sleep reactivity",
    short: "Sleep reactivity paper",
    filename: "2014 Kalmbach et al J Sleep Res {24687}.pdf",
    summary: "Useful for stress-triggered, anxious, and hyperarousal-driven insomnia pages.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  morin_psychosomatic_insomnia: {
    title: "Morin et al. psychosomatic insomnia paper",
    short: "Insomnia psychosomatic burden",
    filename: "2003 Morin et al Psychosom Med {25467}.pdf",
    summary: "Useful for pages that describe insomnia as a whole-person burden touching daytime health and wellbeing.",
    groups: %i[insomnia_and_fragmentation]
  },
  tang_sleep_emotion: {
    title: "Tang et al. Sleep on sleep and emotion regulation",
    short: "Sleep and emotion regulation",
    filename: "2012 Tang et al Sleep {25455}.pdf",
    summary: "Useful for pages that connect poor sleep with emotional volatility, stress sensitivity, and next-day self-regulation.",
    groups: %i[insomnia_and_fragmentation neuropsych_and_complex]
  },
  de_bruin_mindfulness: {
    title: "de Bruin et al. Mindfulness and sleep",
    short: "Mindfulness and sleep",
    filename: "2017 de Bruin et al Mindfulness {25407}.pdf",
    summary: "Useful for pages that recommend mindfulness-style downshifting, especially in stress-sensitive or insomnia patterns.",
    groups: %i[insomnia_and_fragmentation nonrestorative_and_optimization]
  },
  hafner_productivity: {
    title: "Hafner et al. RAND on sleep and productivity",
    short: "Sleep and productivity costs",
    filename: "2017 Hafner et al Rand Health Q {25379}.pdf",
    summary: "Useful for workload and recovery pages that frame sleep loss as an individual and organizational performance cost.",
    groups: %i[quantity_and_life_constraints]
  },
  st_onge_cardiometabolic: {
    title: "St-Onge et al. Circulation on sleep and cardiometabolic health",
    short: "Sleep and cardiometabolic health",
    filename: "2016 St-Onge et al Circulation {25374}.pdf",
    summary: "Useful for pages that connect insufficient or poor-quality sleep with cardiometabolic burden.",
    groups: %i[quantity_and_life_constraints nonrestorative_and_optimization special_overlap_profiles_a]
  },
  baron_social_jetlag: {
    title: "Baron et al. on social jet lag and health behavior",
    short: "Social jet lag paper",
    filename: "2013 Baron et al J Clin Sleep Med {25371}.pdf",
    summary: "Useful for night-owl, delayed-clock, and inconsistent-schedule pages.",
    groups: %i[circadian_and_schedule special_overlap_profiles_b]
  },
  redline_osa_population: {
    title: "Redline et al. population respiratory sleep paper",
    short: "Population sleep breathing paper",
    filename: "2014 Redline et al Am J Respir Crit Care Med {.pdf",
    summary: "Useful for airway overlap pages that need broader epidemiologic grounding for sleep-disordered breathing burden.",
    groups: %i[airway_environment_and_physical special_overlap_profiles_a]
  },
  dolezal_exercise_sleep_review: {
    title: "Dolezal et al. on exercise and sleep",
    short: "Exercise-sleep prevention review",
    filename: "2017 Dolezal et al Adv Prev Med {25303}.pdf",
    summary: "Useful for pages about exercise as a lever for better sleep quality and restoration.",
    groups: %i[nonrestorative_and_optimization optimum_sleepers quantity_and_life_constraints]
  },
  bei_sleep_quality: {
    title: "Bei et al. Journal of Sleep Research on sleep quality constructs",
    short: "Sleep quality constructs",
    filename: "2014 Bei et al J Sleep Res {25289}.pdf",
    summary: "Useful for pages that distinguish sleep quantity from subjective sleep quality and restoration.",
    groups: %i[nonrestorative_and_optimization general_foundation insomnia_and_fragmentation]
  },
  shochat_sleepiness_youth: {
    title: "Shochat et al. Sleep Medicine Reviews on excessive sleepiness",
    short: "Excessive sleepiness review",
    filename: "2014 Shochat et al Sleep Med Rev {25287}.pdf",
    summary: "Useful for pages where the main story is waking unrefreshed, daytime sleepiness, or schedule-driven fatigue.",
    groups: %i[quantity_and_life_constraints circadian_and_schedule nonrestorative_and_optimization]
  },
  chennaoui_sleep_recovery: {
    title: "Chennaoui et al. Sleep Medicine on sleep and recovery",
    short: "Sleep and physiologic recovery",
    filename: "2014 Chennaoui et al Sleep Medicine {25284}.pdf",
    summary: "Useful for performance and recovery pages that describe sleep as a core regenerative process.",
    groups: %i[optimum_sleepers nonrestorative_and_optimization]
  }
}.freeze

ALL_LIBRARY_REFERENCES = LIBRARY_REFERENCES
  .merge(EXTRA_LIBRARY_REFERENCES)
  .merge(EXTRA_LIBRARY_REFERENCES_2)
  .freeze

SLEEP_SPACE_RESOURCES = {
  learn: {
    title: "Sleep Science Blog | Learn Everything About the Sleep Revolution",
    short: "SleepSpace learning hub",
    url: "https://sleepspace.com/learn-about-sleep/",
    note: "A broad SleepSpace article library that can serve as the hub resource on every page."
  },
  science: {
    title: "SleepSpace Science",
    short: "SleepSpace science page",
    url: "https://sleepspace.com/science",
    note: "Useful when the page needs a product-adjacent evidence destination."
  },
  cbti_program: {
    title: "Best CBTi Based Program | Get Better Sleep with SleepSpace",
    short: "SleepSpace CBT-I program",
    url: "https://sleepspace.com/cognitive-behavioral-therapy/",
    note: "Useful for insomnia-heavy pages where the intervention logic is behavioral."
  },
  circadian_schedule: {
    title: "Weekly Sleep Schedule App + Smart Alarm Automation",
    short: "Circadian schedule guide",
    url: "https://sleepspace.com/circadian-sleep-schedule/",
    note: "Useful for circadian, travel, and timing-mismatch pages."
  },
  tracking: {
    title: "5 Ways to Track Your Sleep | Wearables | Nearables | Sleep Diary",
    short: "Tracking and wearables guide",
    url: "https://sleepspace.com/5-ways-to-track/",
    note: "Useful for pages that emphasize data quality, sleep diaries, and wearables."
  },
  sound_masking: {
    title: "Using sound masking technology to improve sleep",
    short: "Sound masking guide",
    url: "https://sleepspace.com/sound-masking-technology/",
    note: "Useful for noise, partner, and light-sleeper pages."
  },
  snore_tracking: {
    title: "Track snoring, breathing, & room sounds | Listen to sleep apnea",
    short: "Snoring and breathing tracking guide",
    url: "https://sleepspace.com/track-snoring/",
    note: "Useful for airway, snoring, and breathing-disruption pages."
  },
  phone_system: {
    title: "SleepSpace Phone — The All-in-One Sleep System",
    short: "SleepSpace Phone system",
    url: "https://sleepspace.com/sleepspace-phone-benefits/",
    note: "Useful for pages that talk about integrated tracking, environment control, and bedside sleep technology."
  }
}.freeze

GROUP_REFERENCE_KEYS = {
  insomnia_and_fragmentation: {
    web: %i[hyperarousal_review cbti_meta digital_cbti stress_reactivity],
    library: %i[
      digital_cbti_outcomes somryst_profile dream_protocol cbti_cognition
      sleepspace_validation_insomnia sleepspace_bsm_submission sleepspace_protocol_slides
      mental_health_tsuno insomnia_linton anxiety_alfano adhd_becker work_sleep_crain
      psqi_buysse fichtenberg_insomnia_neuropsych mcglinchey_harvey_insomnia
      pieters_sleep_affect friborg_sleep_quality alvaro_sleep_depression
      roberts_behav_sleep_med haimov_insomnia_older cricco_older_adults
      roth_insomnia_daytime kalmbach_sleep_reactivity morin_psychosomatic_insomnia
      tang_sleep_emotion de_bruin_mindfulness akerstedt_work_recovery
    ],
    resources: %i[learn science cbti_program sound_masking]
  },
  circadian_and_schedule: {
    web: %i[delayed_phase_review melatonin_trial shift_work_review circadian_review jet_lag_review],
    library: %i[
      ereader_circadian wearables_science sleepspace_actigraphy_session
      actigraphy_sadeh_review circadian_shoji circadian_sekine student_sleep_hershner_clin
      student_sleep_hershner_nat student_sleep_kelly shift_work_kubo circadian_vitale
      adhd_becker hasler_circadian_affect kwv251_circadian womack_shift_performance
      terry_mcelrath_adolescent_sleep sagaspe_sleepiness_performance
      cain_gradisar_adolescent bauer_bipolar_circadian baron_social_jetlag
      shochat_sleepiness_youth marino_measurement_accuracy
    ],
    resources: %i[learn science circadian_schedule tracking]
  },
  quantity_and_life_constraints: {
    web: %i[sleep_deprivation_review nhlbi_sleep_deprivation stress_reactivity],
    library: %i[
      sleep_recommendation wearables_science sleepspace_actigraphy_session
      actigraphy_cole_richards actigraphy_sadeh_review work_sleep_germeys work_sleep_crain
      public_health_grandner sleep_health_jackson lifestyle_kline student_sleep_hershner_clin
      student_sleep_hershner_nat student_sleep_kelly population_sleep_fox population_sleep_full
      metabolism_bianchi metabolism_swanson metabolism_buxton sleep_deprived_human_brain
      thomas_sleepiness_2000 thomas_2015_sleep_loss terry_mcelrath_adolescent_sleep
      daly_work_sleep edwards_work_sleep rosekind_fatigue_work hafner_productivity
      st_onge_cardiometabolic shochat_sleepiness_youth sagaspe_sleepiness_performance
      passos_exercise_sleep
    ],
    resources: %i[learn science tracking phone_system]
  },
  airway_environment_and_physical: {
    web: %i[positional_therapy oral_appliance rls_review noise_review heat_review pain_sleep_review partner_review],
    library: %i[sleep_apnea_sonar predict_osa_photo predict_osa_3d noise_performance],
    resources: %i[learn science snore_tracking sound_masking tracking]
  },
  nonrestorative_and_optimization: {
    web: %i[nonrestorative_sleep athlete_recovery mindfulness_sleep sleep_deprivation_review],
    library: %i[
      wearables_science acoustic_stimulation modius_study boosting_recovery rem_sws_brain_atrophy
      wearables_image cbti_cognition sleepspace_validation_insomnia sleepspace_bsm_submission
      sleepspace_ms_draft sleepspace_poster_final sleepspace_aacsm sleepspace_ubiquitous_computing
      public_health_grandner lifestyle_kline immune_sleep_besedovsky memory_ngo memory_ladenbauer
      memory_lafortune synaptic_tononi aging_scullin_bliwise metabolism_bianchi metabolism_swanson
      measurement_van_hees measurement_agreement psqi_buysse marino_measurement_accuracy
      wong_sleep_measurement_2011 wong_sleep_measurement_2015 wong_sleep_measurement_2016
      sleep_deprived_human_brain thomas_sleepiness_2000 thomas_2015_sleep_loss
      friborg_sleep_quality oosterman_sleep_cognition zhang_pnas_sleep_deprivation
      st_onge_cardiometabolic driver_taylor_exercise youngstedt_exercise_sleep
      dolezal_exercise_sleep_review bei_sleep_quality shochat_sleepiness_youth
      chennaoui_sleep_recovery passos_exercise_sleep de_bruin_mindfulness
    ],
    resources: %i[learn science tracking phone_system sound_masking]
  },
  optimum_sleepers: {
    web: %i[athlete_recovery mindfulness_sleep nonrestorative_sleep],
    library: %i[
      wearables_science acoustic_stimulation modius_study boosting_recovery targeted_memory_reactivation
      rem_sws_brain_atrophy wearables_image circadian_vitale immune_sleep_besedovsky memory_ngo
      memory_ladenbauer synaptic_tononi memory_pace_schott youngstedt_exercise_sleep
      driver_taylor_exercise dolezal_exercise_sleep_review chennaoui_sleep_recovery
    ],
    resources: %i[learn science tracking phone_system]
  },
  neuropsych_and_complex: {
    web: %i[sleep_paralysis_review sleep_paralysis_features rbd_review sleep_inertia stress_reactivity],
    library: %i[
      targeted_memory_reactivation rem_sws_brain_atrophy wearables_science memory_ngo memory_ladenbauer
      memory_lafortune memory_pace_schott aging_scullin_bliwise mental_health_tsuno insomnia_linton
      anxiety_alfano adhd_becker hasler_circadian_affect bauer_bipolar_circadian
      fichtenberg_insomnia_neuropsych pieters_sleep_affect alvaro_sleep_depression
      oosterman_sleep_cognition tang_sleep_emotion
    ],
    resources: %i[learn science tracking cbti_program]
  },
  special_overlap_profiles_a: {
    web: %i[positional_therapy oral_appliance central_apnea_review central_apnea_guideline],
    library: %i[sleep_apnea_sonar predict_osa_photo predict_osa_3d stopbang_mortality osa_hypertension cpap_adherence mad_mouth_closing],
    resources: %i[learn science snore_tracking tracking]
  },
  special_overlap_profiles_b: {
    web: %i[jet_lag_review grief_sleep seasonal_sleep nhlbi_sleep_deprivation],
    library: %i[
      sleep_recommendation wearables_science wearables_image ereader_circadian circadian_shoji
      circadian_sekine work_sleep_germeys shift_work_kubo sleep_evolution
      kwv251_circadian womack_shift_performance tavernier_sleep_alcohol
      baron_social_jetlag rosekind_fatigue_work
    ],
    resources: %i[learn science tracking circadian_schedule phone_system]
  },
  general_foundation: {
    web: %i[nhlbi_sleep_deprivation nonrestorative_sleep],
    library: %i[
      wearables_science wearables_image sleepspace_bsm_submission sleepspace_ms_draft
      sleepspace_poster_final sleepspace_aacsm sleepspace_actigraphy_session
      sleepspace_ubiquitous_computing actigraphy_cole_richards actigraphy_sadeh_review
      public_health_grandner sleep_health_jackson population_sleep_fox population_sleep_full
      measurement_van_hees measurement_agreement sleep_evolution psqi_buysse
      marino_measurement_accuracy wong_sleep_measurement_2011 wong_sleep_measurement_2015
      wong_sleep_measurement_2016 grandner_jcsm_sleep_health
    ],
    resources: %i[learn science tracking]
  }
}.freeze

PHENOTYPE_REFERENCE_OVERRIDES = {
  armadillo_restless_legs: { web: %i[rls_review nonrestorative_sleep], library: %i[wearables_science] },
  porcupine_pain_tosser: { web: %i[pain_sleep_review cbti_meta], library: %i[wearables_science] },
  meerkat_noise_guard: { web: %i[noise_review nonrestorative_sleep], library: %i[noise_performance] },
  penguin_partner_poked: { web: %i[partner_review nonrestorative_sleep], library: %i[wearables_science] },
  lizard_heat_kicker: { web: %i[heat_review nonrestorative_sleep], library: %i[wearables_science] },
  whale_altitude_breather: { web: %i[central_apnea_review nhlbi_sleep_deprivation], library: %i[sleep_apnea_sonar] },
  peacock_sleep_paralysis: { web: %i[sleep_paralysis_review sleep_paralysis_features sleep_inertia], library: %i[wearables_science] },
  platypus_dream_actor: { web: %i[rbd_review nonrestorative_sleep], library: %i[targeted_memory_reactivation] },
  monkey_dream_intense: { web: %i[rbd_review stress_reactivity nonrestorative_sleep], library: %i[targeted_memory_reactivation rem_sws_brain_atrophy] },
  turtle_slow_starter: { web: %i[sleep_inertia sleep_deprivation_review], library: %i[wearables_science] },
  bee_stress_sensitive: { web: %i[stress_reactivity hyperarousal_review], library: %i[cbti_cognition] },
  ostrich_escape_sleeper: { web: %i[hyperarousal_review cbti_meta stress_reactivity], library: %i[somryst_profile digital_cbti_outcomes] },
  bison_apnea_insomnia: { web: %i[central_apnea_guideline oral_appliance cbti_meta], library: %i[sleep_apnea_sonar stopbang_mortality somryst_profile] },
  rhino_explosive_snorer: { web: %i[oral_appliance positional_therapy], library: %i[predict_osa_photo predict_osa_3d sleep_apnea_sonar] },
  alligator_bruxing_breather: { web: %i[oral_appliance central_apnea_review], library: %i[mad_mouth_closing predict_osa_photo] },
  boar_alcohol_airway: { web: %i[oral_appliance positional_therapy nhlbi_sleep_deprivation], library: %i[osa_hypertension] },
  goose_self_snore_waker: { web: %i[oral_appliance positional_therapy], library: %i[sleep_apnea_sonar] },
  moose_positional_breather: { web: %i[positional_therapy oral_appliance], library: %i[predict_osa_photo predict_osa_3d] },
  sea_lion_central_breather: { web: %i[central_apnea_review central_apnea_guideline], library: %i[sleep_apnea_sonar stopbang_mortality] },
  seal_seasonal_adapter: { web: %i[seasonal_sleep circadian_review], library: %i[ereader_circadian wearables_science] },
  sloth_high_sleep_need: { web: %i[nonrestorative_sleep nhlbi_sleep_deprivation], library: %i[sleep_recommendation] },
  swallow_frequent_traveler: { web: %i[jet_lag_review circadian_review], library: %i[ereader_circadian wearables_science] },
  vulture_grief_sleeper: { web: %i[grief_sleep stress_reactivity], library: %i[cbti_cognition] },
  squirrel_stress_triggered: { web: %i[stress_reactivity hyperarousal_review], library: %i[cbti_cognition] }
}.freeze

REMOTE_IMAGE_MAP = {
  "hawk" => "https://sleepspace.com/wp-content/uploads/2026/04/Proud-hawk-perched-under-the-stars.png",
  "elephant" => "https://sleepspace.com/wp-content/uploads/2026/04/Sleeping-elephant-under-a-starry-sky.png",
  "dog" => "https://sleepspace.com/wp-content/uploads/2026/04/Sleeping-dog-under-a-starry-night.png",
  "bear" => "https://sleepspace.com/wp-content/uploads/2026/04/Sleepy-bear-under-starry-skies.png",
  "koala" => "https://sleepspace.com/wp-content/uploads/2026/04/Koala-sleeping-under-starry-skies.png",
  "otter" => "https://sleepspace.com/wp-content/uploads/2026/04/Sleeping-otter-under-the-stars.png"
}.freeze

SPIDER_IMAGES = {
  bedside: "https://sleepspace.com/wp-content/uploads/2024/09/SleepSpace-bedside.webp",
  footer: "https://sleepspace.com/wp-content/uploads/2022/06/footer-image-resized.png",
  pyramid: "https://sleepspace.com/wp-content/uploads/2026/04/Sleep-health-pyramid-infographic.png",
  wearables: "./assets/sleepspace-with-wearables.png"
}.freeze

KEYWORD_STOPWORDS = %w[
  and the for with from article review overview study studies main full pdf
  et al in of to on by a an using use based effects effect clinical research
  journal sleep article main covered product introduction protocol example
  versus among adults adult child children can could should more less
  report reports patient patients supplementary supplement production prod
  s2 nihms piis jcsm aasm zsaa zsad zsac zsae zsy zsz fnagi fneur fpsyt fpsyg
  jtd jnnp joph ijms ijerph kjp tjo ijo bmjophth ad procats
].freeze

def h(text)
  CGI.escapeHTML(text.to_s)
end

def slug_for_key(key)
  key.to_s.tr("_", "-")
end

def group_meta_for(key)
  GROUP_META.fetch(GROUP_BY_KEY.fetch(key))
end

def local_or_placeholder_image_path(phenotype)
  basename = phenotype.fetch(:image).sub(/\Aanimal-/, "")
  slug = File.basename(basename, ".png")
  local_path = File.join(ROOT, "assets", "animals", basename)

  return REMOTE_IMAGE_MAP.fetch(slug) if REMOTE_IMAGE_MAP.key?(slug)
  return "../assets/animals/#{basename}" if File.exist?(local_path)

  placeholder_path = File.join(PLACEHOLDER_DIR, "#{slug}.svg")
  unless File.exist?(placeholder_path)
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 900" role="img" aria-labelledby="#{slug}-title #{slug}-desc">
        <title id="#{slug}-title">#{h(phenotype.fetch(:animal_name))} placeholder illustration</title>
        <desc id="#{slug}-desc">Placeholder artwork for the #{h(phenotype.fetch(:animal_name))} sleep animal.</desc>
        <defs>
          <linearGradient id="bg" x1="0%" x2="100%" y1="0%" y2="100%">
            <stop offset="0%" stop-color="#081c34" />
            <stop offset="45%" stop-color="#0d3456" />
            <stop offset="100%" stop-color="#14233f" />
          </linearGradient>
          <radialGradient id="glow" cx="50%" cy="35%" r="60%">
            <stop offset="0%" stop-color="#f5d7b5" stop-opacity="0.85" />
            <stop offset="100%" stop-color="#f5d7b5" stop-opacity="0" />
          </radialGradient>
        </defs>
        <rect width="1200" height="900" fill="url(#bg)" />
        <circle cx="820" cy="200" r="230" fill="url(#glow)" />
        <path d="M0 690 C160 640 250 700 390 650 C550 595 670 730 820 665 C935 615 1070 660 1200 610 L1200 900 L0 900 Z" fill="#0a1730" />
        <path d="M0 745 C150 695 310 780 480 715 C640 660 760 805 915 730 C1040 670 1120 700 1200 675 L1200 900 L0 900 Z" fill="#081225" opacity="0.9" />
        <circle cx="600" cy="410" r="122" fill="none" stroke="#f4c49b" stroke-opacity="0.92" stroke-width="6" />
        <text x="600" y="428" fill="#fff8ef" font-family="Avenir Next, Trebuchet MS, Segoe UI, sans-serif" font-size="84" font-weight="700" text-anchor="middle">#{h(phenotype.fetch(:animal_name))}</text>
        <text x="600" y="520" fill="#f0c9b3" font-family="Avenir Next, Trebuchet MS, Segoe UI, sans-serif" font-size="34" font-weight="600" text-anchor="middle">#{h(phenotype.fetch(:title))}</text>
        <text x="600" y="588" fill="#b9cfdd" font-family="Avenir Next, Trebuchet MS, Segoe UI, sans-serif" font-size="26" text-anchor="middle">Sleep animal illustration placeholder</text>
      </svg>
    SVG
    File.write(placeholder_path, svg)
  end

  "./placeholders/#{slug}.svg"
end

def base_reference_keys_for(group)
  GROUP_REFERENCE_KEYS.fetch(group)
end

def reference_payload_for(key)
  group = GROUP_BY_KEY.fetch(key)
  payload = Marshal.load(Marshal.dump(base_reference_keys_for(group)))
  override = PHENOTYPE_REFERENCE_OVERRIDES[key]

  if override
    payload[:web] = (payload[:web] + Array(override[:web])).uniq
    payload[:library] = (payload[:library] + Array(override[:library])).uniq
  end

  payload
end

def page_references_for(key)
  payload = reference_payload_for(key)
  refs = []

  payload[:library].each do |ref_key|
    ref = ALL_LIBRARY_REFERENCES.fetch(ref_key).merge(kind: :library, key: ref_key)
    refs << ref
  end

  payload[:web].each do |ref_key|
    ref = WEB_REFERENCES.fetch(ref_key).merge(kind: :web, key: ref_key)
    refs << ref
  end

  payload[:resources].each do |ref_key|
    ref = SLEEP_SPACE_RESOURCES.fetch(ref_key).merge(kind: :resource, key: ref_key)
    refs << ref
  end

  refs
end

def citation_map(references)
  references.each_with_index.each_with_object({}) do |(ref, idx), memo|
    memo[ref.fetch(:key)] = idx + 1
  end
end

def cite(map, *keys)
  keys.flatten.uniq.map do |key|
    next unless map.key?(key)

    number = map.fetch(key)
    %(<a class="sap-cite" href="#ref-#{number}">[#{number}]</a>)
  end.compact.join(" ")
end

def symptom_list_for(key, phenotype)
  group = GROUP_BY_KEY.fetch(key)
  base = case group
  when :insomnia_and_fragmentation
    [
      "Bedtime feels effortful even when the body is tired.",
      "The night is often broken by cognitive arousal, anticipatory worry, or light sleep continuity.",
      "Next-day fatigue can coexist with a nervous system that still feels accelerated.",
      "A structured routine often works better than trying harder to sleep."
    ]
  when :circadian_and_schedule
    [
      "The sleeper often feels competent at sleeping, but at the wrong time for real life.",
      "Workdays and free days can drift apart, creating a social-jet-lag effect.",
      "Light exposure, schedule anchors, and travel pressure matter more than people realize.",
      "The right intervention usually targets timing first, not only relaxation."
    ]
  when :quantity_and_life_constraints
    [
      "Sleep opportunity is often squeezed by workload, parenting, commuting, or care responsibilities.",
      "Fatigue can become normalized because the sleeper is highly functional under load.",
      "Random catch-up sleep rarely feels as good as a more protected baseline schedule.",
      "The phenotype improves when recovery is scheduled deliberately rather than borrowed."
    ]
  when :airway_environment_and_physical
    [
      "The body or the room keeps disturbing the night, even if total time in bed looks adequate.",
      "The sleeper may not always recognize the night as fragmented until daytime restoration drops.",
      "Not every page in this cluster implies the same level of medical urgency, but many benefit from screening.",
      "Environment, position, pain load, sound, and partner factors can all amplify the core problem."
    ]
  when :nonrestorative_and_optimization
    [
      "The central question is whether the night actually pays out in restoration.",
      "Tracking can be especially useful because people often overestimate or underestimate the quality of a decent-looking night.",
      "Small changes in rhythm, environment, or recovery rituals can produce outsized improvements.",
      "This cluster often benefits from distinguishing sleep quantity from sleep architecture and recovery quality."
    ]
  when :optimum_sleepers
    [
      "The sleeper already has a comparatively strong base and may be optimizing rather than troubleshooting.",
      "Performance, deep recovery, dream richness, or intentional sleep practice often define the experience.",
      "The risk is not only losing good sleep, but losing the habits that quietly support it.",
      "These phenotypes are strongest when tracked over time rather than judged from one unusually good or bad night."
    ]
  when :neuropsych_and_complex
    [
      "The unusual part of the night often happens at the transition between sleep, dreaming, and waking.",
      "Stress, sleep loss, and schedule instability can amplify the pattern even if they do not fully explain it.",
      "The sleeper may describe the night as unsettling, vivid, sticky, or neurologically strange.",
      "This cluster benefits from both symptom description and careful normalization where appropriate."
    ]
  when :special_overlap_profiles_a
    [
      "Airway strain often overlaps with another modifier such as position, insomnia, alcohol, or jaw tension.",
      "The overlap matters because it changes how the night feels and how the next step should be framed.",
      "The page should teach the sleeper what to monitor without pretending a single pattern explains everything.",
      "Screening, adherence, and anatomy-sensitive interpretation often matter more here than generic sleep hygiene."
    ]
  when :special_overlap_profiles_b
    [
      "The sleeper may look different in different seasons, life chapters, or travel weeks.",
      "A multi-night or multi-context perspective is often more revealing than a single snapshot.",
      "Portable routines matter because consistency is being challenged by external context.",
      "The most helpful framing is often adaptive rather than pathologizing."
    ]
  else
    [
      "The signal set is mixed enough that the best move is still to improve the clarity of the data.",
      "This result is often seen when several mild pressures coexist without one obviously dominating.",
      "The page is most useful when it helps the sleeper collect cleaner signals over the next one to three weeks.",
      "A non-specific result can still prevent the wrong premature conclusion."
    ]
  end

  # Pull the phenotype hook directly into the list to make each page feel anchored.
  ["#{phenotype.fetch(:hook)}"] + base
end

def mechanisms_for(key, phenotype, cites)
  group = GROUP_BY_KEY.fetch(key)
  animal = phenotype.fetch(:animal_name)
  title = phenotype.fetch(:title)

  case group
  when :insomnia_and_fragmentation
    [
      "#{animal} pages are built around the idea that insomnia is often maintained by more than a simple failure to get sleepy. Hyperarousal models describe a system that stays physiologically and cognitively activated too close to bedtime, which can lengthen sleep latency, lighten sleep, and make awakenings feel more mentally sticky than physically restless. That framing maps well onto the way the #{title.downcase} description is written here. #{cite(cites, :hyperarousal_review, :stress_reactivity)}",
      "The second layer is behavioral conditioning. Once the bed becomes associated with trying, monitoring, frustration, or mental rehearsal, the difficulty can reinforce itself night after night. That is why these pages lean heavily on structured routine, stimulus control, cognitive unloading, and schedule steadiness rather than generic advice to just relax more. #{cite(cites, :cbti_meta, :digital_cbti)}",
      "Your local citation library also leans in this direction. The insomnia-focused digital therapeutic and outcome papers in your folder make it easier to justify a product-facing bridge from phenotype language to a structured behavioral program, especially for people who need support with implementation rather than more theory. #{cite(cites, :digital_cbti_outcomes, :somryst_profile, :dream_protocol, :cbti_cognition)}"
    ]
  when :circadian_and_schedule
    [
      "For this cluster, the central question is often not whether the sleeper can sleep, but when the underlying clock wants sleep to occur. Delayed and advanced timing disorders, shift work, and travel all create a mismatch between biologic night and social night, which can look like insomnia from the outside even when the deeper issue is circadian misalignment. #{cite(cites, :delayed_phase_review, :circadian_review)}",
      "That is why the wording on pages like #{animal} does not insist on forcing a new identity overnight. The evidence around schedule anchoring, light exposure, melatonin timing, and shift-work adaptation supports a more strategic and biologically respectful approach. #{cite(cites, :melatonin_trial, :shift_work_review, :jet_lag_review)}",
      "The local file set adds an important practical point: modern evening light environments are not neutral. The e-reader circadian paper in your citation folder is a useful reminder that late light exposure can intensify delay and make morning recovery worse, which fits many of these phenotype narratives. #{cite(cites, :ereader_circadian, :wearables_science)}"
    ]
  when :quantity_and_life_constraints
    [
      "These animals are designed around the possibility that the sleeper is less broken than underfunded. Chronic sleep restriction studies repeatedly show that vigilance, mood, and higher-order function deteriorate even when people subjectively feel they are adapting. In that sense, the phenotype is often a translation of hidden sleep debt into something memorable and actionable. #{cite(cites, :sleep_deprivation_review, :nhlbi_sleep_deprivation)}",
      "The page language therefore emphasizes opportunity cost, workload, caregiving load, and cumulative debt. A Horse, Camel, or Crow page should feel different from an insomnia page because the recommended response is usually to protect and defend sleep opportunity first, then improve sleep quality second. #{cite(cites, :sleep_recommendation)}",
      "The tracking angle matters here too. When life is the constraining factor, wearables and diaries are often most useful not for diagnosing a mysterious disorder, but for revealing how predictable the loss really is and how much recovery is being attempted through naps, weekends, or rebound sleep. #{cite(cites, :wearables_science, :tracking)}"
    ]
  when :airway_environment_and_physical
    [
      "This cluster is built around the idea that the night can be damaged from below awareness. Snoring, airway resistance, pain, heat, noise, leg discomfort, and partner disturbance do not all produce the same physiology, but they do share a common outcome: fragmented continuity and weaker next-day restoration. #{cite(cites, :pain_sleep_review, :noise_review, :heat_review, :partner_review)}",
      "The reason the phenotype model is useful here is that it prevents all disrupted nights from sounding interchangeable. A Walrus, Porcupine, Meerkat, or Lizard are all tired in different ways. The evidence supporting positional therapy, oral appliances, restless-legs review literature, and environmental sleep disruption makes those differences clinically plausible. #{cite(cites, :positional_therapy, :oral_appliance, :rls_review)}",
      "Your own citation library contributes especially well in the airway corner. The smartphone apnea-detection paper and the craniofacial-photo papers support the idea that breathing phenotypes can vary meaningfully in anatomy, monitoring strategy, and screening logic. #{cite(cites, :sleep_apnea_sonar, :predict_osa_photo, :predict_osa_3d)}"
    ]
  when :nonrestorative_and_optimization
    [
      "This cluster starts from a subtle but important observation: time in bed is not the same thing as biologic restoration. The nonrestorative-sleep literature is useful here because it legitimizes the lived experience of sleepers who technically sleep, yet still feel as though the night failed to do its job. #{cite(cites, :nonrestorative_sleep)}",
      "That matters for pages like #{animal}. The copy can talk about recovery quality, sleep need, sleep architecture, and stable rhythm without pretending that every unrefreshed morning has the same cause. For some sleepers the issue is poor continuity, for others it is under-recovery, and for some it is that a seemingly healthy baseline still benefits from more precise optimization. #{cite(cites, :athlete_recovery, :mindfulness_sleep)}",
      "Your citation library gives this cluster extra depth. The wearables recommendations paper supports careful use of tracking, while the acoustic-stimulation, recovery-during-sleep, and slow-wave/REM papers justify a richer discussion of architecture, deep sleep, and why enhancement-focused readers care about sleep beyond just duration. #{cite(cites, :wearables_science, :acoustic_stimulation, :boosting_recovery, :rem_sws_brain_atrophy)}"
    ]
  when :optimum_sleepers
    [
      "The optimum-sleeper pages are written from an unusual but important stance: sleep can be good enough to preserve rather than simply bad enough to fix. Athletic recovery and mindfulness literature both help here because they show that good sleep is not passive luck; it is often supported by routines, load management, autonomic regulation, and intentionally protected timing. #{cite(cites, :athlete_recovery, :mindfulness_sleep)}",
      "That makes pages like #{animal} useful for readers who are already functioning well and want to know how to keep the advantage. The narrative can legitimately focus on protecting architecture, supporting next-day performance, and preserving a strong sleep base during stress, travel, or intense training blocks. #{cite(cites, :nonrestorative_sleep, :wearables_science)}",
      "Your local library contributes several interesting enhancement-oriented references, including acoustic stimulation, recovery-boosting, targeted memory reactivation, and slow-wave or REM quality papers. Those are not blanket prescriptions, but they do justify a more sophisticated conversation about optimization than a typical sleep-hygiene page. #{cite(cites, :acoustic_stimulation, :boosting_recovery, :targeted_memory_reactivation, :rem_sws_brain_atrophy)}"
    ]
  when :neuropsych_and_complex
    [
      "These pages are strongest when they frame unusual experiences at the boundaries of sleep as recognizable patterns rather than isolated oddities. Sleep paralysis, REM-related dream enactment, and sleep inertia each have distinct literatures, and those literatures support describing the experience carefully even when the phenotype itself is not a formal diagnosis. #{cite(cites, :sleep_paralysis_review, :sleep_paralysis_features, :rbd_review, :sleep_inertia)}",
      "Stress and schedule instability still matter in this cluster because they can amplify unstable transitions, vivid dream load, and heavy-morning recovery problems. That is why the pages combine descriptive language with basic protective advice around consistency, sleep debt, and safer transitions into and out of sleep. #{cite(cites, :stress_reactivity)}",
      "Your own citation set broadens the story further. The targeted-memory-reactivation and slow-wave/REM papers are especially useful for dream, memory, and architecture conversations because they remind readers that what happens during sleep is cognitively consequential, not just cosmetically interesting. #{cite(cites, :targeted_memory_reactivation, :rem_sws_brain_atrophy, :wearables_science)}"
    ]
  when :special_overlap_profiles_a
    [
      "The overlap pages exist because breathing-related sleep disruption rarely arrives alone. Position, insomnia, alcohol, jaw tension, self-awakening from snoring, and central-pattern complexity all change how the night feels and therefore what kind of explanation will resonate with the sleeper. #{cite(cites, :positional_therapy, :oral_appliance, :central_apnea_review)}",
      "That overlap logic is particularly important in phenotype writing. A Bison should not read like a Rhino, and a Sea Lion should not sound interchangeable with a Walrus. The guideline and review literature support that distinction by showing that the intervention path depends on the type of breathing burden and the context around it. #{cite(cites, :central_apnea_guideline, :oral_appliance)}",
      "This is also where your local library is especially strong. The STOP-Bang mortality resource, apnea-hypertension paper, CPAP dose-response paper, and monitoring or photo-analysis papers all support a more serious treatment of breathing clues without forcing every page into the same risk script. #{cite(cites, :stopbang_mortality, :osa_hypertension, :cpap_adherence, :predict_osa_photo, :sleep_apnea_sonar)}"
    ]
  when :special_overlap_profiles_b
    [
      "These pages are intentionally context-sensitive. Season, travel, grief, changing work structure, late performance windows, and unusually high sleep need all alter how a sleeper appears across weeks and months. That makes the phenotype less about a permanent trait and more about a recurring adaptive pattern. #{cite(cites, :jet_lag_review, :grief_sleep, :seasonal_sleep)}",
      "The right long-form explanation therefore highlights portability, timing anchors, and the value of multi-night data. A Swallow or Seal page should make the reader feel seen not because the problem is exotic, but because the pattern only emerges when sleep is observed across changing environments. #{cite(cites, :wearables_science, :sleep_recommendation)}",
      "In your local library, the evening-light paper and wearables recommendations help explain why these pages often discuss both context and tracking. External demands change the sleeper, and a better longitudinal data stream makes the pattern clearer. #{cite(cites, :ereader_circadian, :wearables_science)}"
    ]
  else
    [
      "The mixed-pattern page is built around a conservative scientific idea: uncertain data should lead to a tighter foundation, not a louder claim. When multiple mild pressures coexist, the most evidence-aligned next step is often improved tracking, more stable routines, and a short interval of observation before overcommitting to a narrow label. #{cite(cites, :nhlbi_sleep_deprivation, :nonrestorative_sleep)}",
      "That is why the page emphasizes data quality, trend consistency, and the value of better measurement tools rather than a theatrical diagnosis. A mixed pattern can still be useful if it prevents the wrong intervention. #{cite(cites, :wearables_science, :tracking)}"
    ]
  end
end

def tracking_paragraphs_for(key, cites)
  group = GROUP_BY_KEY.fetch(key)

  paragraph_one = case group
  when :insomnia_and_fragmentation
    "For this cluster, a useful tracking set usually includes bedtime regularity, sleep latency, overnight wake duration, and whether the night gets worse when stress or cognitive load spikes. Wearables can add trend context, but the diary remains central because much of the phenotype depends on the subjective experience of effortful sleep."
  when :circadian_and_schedule
    "Here, the most revealing signals are often the gap between workdays and free days, consistency of rise time, timing of light exposure, and how quickly the schedule shifts after travel or rotating work. A diary plus wearable timing trend is often more informative than a single sleep score."
  when :quantity_and_life_constraints
    "The tracking goal is to expose where recovery is actually being lost. Time in bed, total sleep time, naps, rebound weekends, and variation across high-load versus low-load days usually matter more than intricate stage interpretation."
  when :airway_environment_and_physical
    "For these pages, useful data include sound events, snoring patterns, room conditions, awakenings, position notes, partner disturbance, and how often the sleeper wakes unrefreshed despite apparently adequate time in bed."
  when :nonrestorative_and_optimization, :optimum_sleepers
    "The most useful data usually combine diary context with wearables: consistency, recovery trends, overnight fragmentation, timing, and whether the sleeper's subjective readiness matches the objective-looking night."
  when :neuropsych_and_complex
    "For this cluster, event notes matter: episodes of paralysis, dream enactment, vivid dream intensity, unusually sticky grogginess, or nights that feel neurologically different from baseline. Structured notes make the pattern easier to detect than a generic morning rating alone."
  else
    "Because these patterns change with context, the best data are often multi-night and multi-setting: travel versus home, stressful versus calm weeks, winter versus summer, and high-demand versus lower-demand periods."
  end

  [
    "#{paragraph_one} #{cite(cites, :wearables_science, :tracking)}",
    "SleepSpace's own tracking and wearables articles are especially relevant for these pages because they reinforce the difference between a one-night impression and an interpretable pattern. That is useful for every phenotype, but it becomes essential when the mechanism changes with context. #{cite(cites, :learn, :tracking, :science)}"
  ]
end

def article_cards_for(key)
  resource_keys = reference_payload_for(key).fetch(:resources)
  resource_keys.map do |resource_key|
    SLEEP_SPACE_RESOURCES.fetch(resource_key)
  end
end

def normalize_keyword_token(token)
  cleaned = token.downcase.gsub(/[^a-z0-9]+/, " ").strip
  return nil if cleaned.empty?
  return nil if cleaned.length < 3
  return nil if cleaned.match?(/\A\d+\z/)
  return nil if cleaned.count("0-9") >= 3
  return nil unless cleaned.match?(/[aeiou]/)
  return nil if KEYWORD_STOPWORDS.include?(cleaned)

  cleaned
end

def page_keywords_for(key, phenotype)
  payload = reference_payload_for(key)
  selected_titles = (
    payload.fetch(:library).map { |library_key| ALL_LIBRARY_REFERENCES.fetch(library_key).fetch(:title) } +
    payload.fetch(:web).map { |web_key| WEB_REFERENCES.fetch(web_key).fetch(:title) } +
    payload.fetch(:resources).map { |resource_key| SLEEP_SPACE_RESOURCES.fetch(resource_key).fetch(:title) } +
    payload.fetch(:library).map { |library_key| ALL_LIBRARY_REFERENCES.fetch(library_key).fetch(:filename) }
  )

  seed_terms = [
    phenotype.fetch(:animal_name),
    phenotype.fetch(:title),
    GROUP_META.fetch(GROUP_BY_KEY.fetch(key)).fetch(:label),
    selected_titles.join(" ")
  ].join(" ").downcase.split(/\W+/).map { |token| normalize_keyword_token(token) }.compact

  weighted = Hash.new(0)

  seed_terms.each { |term| weighted[term] += 5 }

  weighted
    .sort_by { |term, score| [-score, term] }
    .first(36)
    .map(&:first)
end

def local_library_cards_for(key)
  payload = reference_payload_for(key)
  payload.fetch(:library).map { |library_key| ALL_LIBRARY_REFERENCES.fetch(library_key) }
end

def overview_paragraphs_for(key, phenotype, cites)
  group = GROUP_BY_KEY.fetch(key)
  meta = GROUP_META.fetch(group)
  keyword_bank = page_keywords_for(key, phenotype)
  top_keywords = keyword_bank.first(18)

  [
    "#{phenotype.fetch(:description)} This long-form page treats #{phenotype.fetch(:animal_name)} as a sleep phenotype: a memorable wrapper around a recurring pattern that likely clusters across schedule, physiology, stress load, and next-day restoration. The goal is not to claim a formal diagnosis. The goal is to make the likely mechanism more understandable and the next step more obvious.",
    "The reason this page sits inside the #{meta.fetch(:label)} cluster is that the dominant explanatory layer is usually #{meta.fetch(:summary).downcase} That cluster-level interpretation is informed by the research and SleepSpace resources selected specifically for this phenotype page. #{cite(cites, *reference_payload_for(key).fetch(:web).first(2))}",
    "Across the sources selected for #{phenotype.fetch(:animal_name)}, the most relevant recurring vocabulary tends to cluster around #{top_keywords.join(', ')}. That keyword mesh helps this page stay anchored to the themes that are actually represented in the current page's citation set, including mechanisms, symptoms, interventions, tracking logic, and next-day consequences."
  ]
end

def caution_paragraph_for(key, cites)
  group = GROUP_BY_KEY.fetch(key)

  case group
  when :airway_environment_and_physical, :special_overlap_profiles_a
    "If loud snoring, observed breathing pauses, gasping, severe daytime sleepiness, or blood-pressure concerns are part of the story, a formal sleep evaluation matters. These pages can orient the sleeper, but they do not replace diagnostic workup for sleep-disordered breathing. #{cite(cites, :central_apnea_guideline, :oral_appliance)}"
  when :neuropsych_and_complex
    "If events involve injury risk, violent dream enactment, very frequent paralysis, profound daytime impairment, or other neurologic red flags, the educational phenotype should not substitute for clinical evaluation. #{cite(cites, :rbd_review, :sleep_paralysis_review)}"
  else
    "The phenotype language is educational and pattern-based. It becomes most useful when paired with trend data, practical experimentation, and medical follow-up when symptoms are severe, persistent, or safety-relevant."
  end
end

def related_keys_for(current_key)
  group = GROUP_BY_KEY.fetch(current_key)
  candidates = GROUPS.fetch(group, []).reject { |key| key == current_key }
  candidates.first(3)
end

def render_html(title:, description:, body:)
  <<~HTML
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>#{h(title)}</title>
        <meta name="description" content="#{h(description)}" />
        <link rel="stylesheet" href="./sleep-animal-pages.css" />
      </head>
      <body class="sap-body">
        #{body}
      </body>
    </html>
  HTML
end

def render_reference_list(references)
  references.each_with_index.map do |ref, idx|
    number = idx + 1
    title = ref.fetch(:title)
    extra = case ref.fetch(:kind)
    when :library
      "Source file: #{ref.fetch(:filename)}"
    when :resource
      ref.fetch(:note)
    else
      ref.fetch(:note)
    end

    link = ref[:url] ? %(<a href="#{h(ref[:url])}" target="_blank" rel="noopener">Open source</a>) : nil
    <<~HTML
      <li id="ref-#{number}" class="sap-reference-item">
        <div>
          <strong>#{h(title)}</strong>
          <p>#{h(extra)}</p>
          #{link || ""}
        </div>
      </li>
    HTML
  end.join
end

def render_page(key, phenotype)
  references = page_references_for(key)
  cites = citation_map(references)
  meta = group_meta_for(key)
  image_path = local_or_placeholder_image_path(phenotype)
  article_cards = article_cards_for(key)
  library_cards = local_library_cards_for(key)
  symptom_list = symptom_list_for(key, phenotype)
  overview = overview_paragraphs_for(key, phenotype, cites)
  mechanisms = mechanisms_for(key, phenotype, cites)
  tracking = tracking_paragraphs_for(key, cites)
  page_keywords = page_keywords_for(key, phenotype)
  related_keys = related_keys_for(key)
  caution = caution_paragraph_for(key, cites)
  slug = slug_for_key(key)

  article_html = article_cards.map do |article|
    <<~HTML
      <article class="sap-card sap-article-card">
        <p class="sap-mini-label">SleepSpace article</p>
        <h3><a href="#{h(article.fetch(:url))}" target="_blank" rel="noopener">#{h(article.fetch(:short))}</a></h3>
        <p>#{h(article.fetch(:note))}</p>
      </article>
    HTML
  end.join

  library_html = library_cards.map do |item|
    <<~HTML
      <article class="sap-card sap-library-card">
        <p class="sap-mini-label">From your citation library</p>
        <h3>#{h(item.fetch(:short))}</h3>
        <p>#{h(item.fetch(:summary))}</p>
        <p class="sap-filename">#{h(item.fetch(:filename))}</p>
      </article>
    HTML
  end.join

  related_html = related_keys.map do |related_key|
    related = PHENOTYPES.fetch(related_key)
    <<~HTML
      <a class="sap-card sap-related-card" href="./#{slug_for_key(related_key)}.html">
        <img src="#{h(local_or_placeholder_image_path(related))}" alt="#{h(related.fetch(:animal_name))} sleep animal illustration" loading="lazy" />
        <div class="sap-card-copy">
          <p class="sap-mini-label">Related animal</p>
          <h3>#{h(related.fetch(:animal_name))}</h3>
          <p>#{h(related.fetch(:title))}</p>
          <p class="sap-card-hook">#{h(related.fetch(:hook))}</p>
        </div>
      </a>
    HTML
  end.join

  symptom_html = symptom_list.map { |item| "<li>#{h(item)}</li>" }.join
  overview_html = overview.map { |p| "<p>#{p}</p>" }.join
  mechanisms_html = mechanisms.map { |p| "<p>#{p}</p>" }.join
  tracking_html = tracking.map { |p| "<p>#{p}</p>" }.join
  axes_html = meta.fetch(:axes).map { |axis| %(<span class="sap-chip">#{h(axis)}</span>) }.join
  keyword_chip_html = page_keywords.map { |term| %(<span class="sap-chip sap-chip-keyword">#{h(term)}</span>) }.join
  secondary_links_html = Array(phenotype[:secondary_links]).uniq.map do |url|
    label = case url
    when /science/
      "SleepSpace Science"
    when /cbt-i|cognitive-behavioral-therapy/
      "SleepSpace CBT-I"
    when /sleep-coaching/
      "SleepSpace Coaching"
    else
      "Learn more"
    end
    %(<a class="sap-button sap-button-secondary" href="#{h(url)}" target="_blank" rel="noopener">#{h(label)}</a>)
  end.join

  body = <<~HTML
    <div class="sap-page">
      <header class="sap-shell sap-topbar">
        <a class="sap-brand" href="./index.html">Sleep Animal Pages</a>
        <nav class="sap-nav">
          <a href="./index.html">Catalog</a>
          <a href="https://app.sleepspace.com/users/sign_up">SleepSpace Quiz</a>
          <a href="https://sleepspace.com/science">Science</a>
          <a href="https://sleepspace.com/learn-about-sleep/">Articles</a>
        </nav>
      </header>

      <main>
        <section class="sap-shell sap-hero">
          <div class="sap-hero-copy">
            <p class="sap-eyebrow">#{h(meta.fetch(:label))} phenotype</p>
            <h1>#{h(phenotype.fetch(:animal_name))}: #{h(phenotype.fetch(:title))}</h1>
            <p class="sap-lede">#{h(phenotype.fetch(:hook))}</p>
            <p>#{h(meta.fetch(:summary))}</p>
            <div class="sap-button-row">
              <a class="sap-button sap-button-primary" href="https://app.sleepspace.com/users/sign_up">Take the SleepSpace quiz</a>
              <a class="sap-button sap-button-secondary" href="./index.html">Browse all #{PHENOTYPES.size} animals</a>
            </div>
            <div class="sap-chip-row">#{axes_html}</div>
          </div>
          <div class="sap-hero-visual">
            <figure class="sap-card sap-hero-image">
              <img src="#{h(image_path)}" alt="#{h(phenotype.fetch(:animal_name))} sleep animal illustration" />
            </figure>
            <div class="sap-hero-stack">
              <figure class="sap-card sap-mini-visual">
                <img src="#{h(SPIDER_IMAGES.fetch(:bedside))}" alt="SleepSpace bedside scene from sleepspace.com" loading="lazy" />
              </figure>
              <figure class="sap-card sap-mini-visual">
                <img src="#{h(SPIDER_IMAGES.fetch(:footer))}" alt="SleepSpace app and watch image from sleepspace.com" loading="lazy" />
              </figure>
            </div>
          </div>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">Interpretation</p>
            <h2>How to read this phenotype</h2>
          </div>
          <div class="sap-prose">#{overview_html}</div>
          <div class="sap-chip-row sap-keyword-row">#{keyword_chip_html}</div>
        </section>

        <section class="sap-shell sap-section sap-split-section">
          <article class="sap-card sap-callout">
            <p class="sap-eyebrow">What this often looks like</p>
            <h2>Common signals in real life</h2>
            <ul class="sap-list">#{symptom_html}</ul>
          </article>
          <article class="sap-card sap-callout">
            <p class="sap-eyebrow">Why this page exists</p>
            <h2>What makes #{h(phenotype.fetch(:animal_name))} distinct</h2>
            <p>#{h(meta.fetch(:pitch))}</p>
            <p>#{h(phenotype.fetch(:ideal_next_step))}</p>
          </article>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">Mechanisms and evidence</p>
            <h2>What the research suggests is going on</h2>
          </div>
          <div class="sap-prose">#{mechanisms_html}</div>
        </section>

        <section class="sap-shell sap-section sap-tracking-layout">
          <div class="sap-tracking-copy">
            <div class="sap-section-heading">
              <p class="sap-eyebrow">Tracking and wearables</p>
              <h2>What data often helps separate this pattern from nearby ones</h2>
            </div>
            <div class="sap-prose">#{tracking_html}</div>
          </div>
          <figure class="sap-card sap-wide-visual">
            <img src="#{h(SPIDER_IMAGES.fetch(:wearables))}" alt="SleepSpace tracking and wearable integrations visual" loading="lazy" />
          </figure>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">SleepSpace article links</p>
            <h2>On-site resources that fit this phenotype</h2>
            <p>These were selected by spidering SleepSpace topic pages and product resources that match the mechanism cluster behind this animal.</p>
          </div>
          <div class="sap-grid sap-article-grid">#{article_html}</div>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">Your citation library</p>
            <h2>Relevant local sources used to shape the page</h2>
            <p>The list below shows the local source files that are actually referenced for this phenotype page.</p>
          </div>
          <div class="sap-grid sap-library-grid">#{library_html}</div>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-card sap-callout sap-caution-card">
            <p class="sap-eyebrow">Important note</p>
            <h2>#{h(phenotype.fetch(:cta_title))}</h2>
            <p>#{caution}</p>
            <p>#{h(phenotype.fetch(:cta_body))}</p>
            <div class="sap-button-row">
              <a class="sap-button sap-button-primary" href="#{h(phenotype.fetch(:primary_link))}" target="_blank" rel="noopener">Open SleepSpace</a>
              #{secondary_links_html}
            </div>
          </div>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">Research references</p>
            <h2>Selected citations for this page</h2>
          </div>
          <ol class="sap-reference-list">
            #{render_reference_list(references)}
          </ol>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">Nearby profiles</p>
            <h2>Other animals in the same neighborhood</h2>
          </div>
          <div class="sap-grid sap-related-grid">#{related_html}</div>
        </section>
      </main>
    </div>
  HTML

  render_html(
    title: "#{phenotype.fetch(:animal_name)} Sleep Animal | #{phenotype.fetch(:title)}",
    description: "#{phenotype.fetch(:animal_name)}: #{phenotype.fetch(:hook)} Long-form evidence-backed SleepSpace phenotype page with citations.",
    body: body
  )
end

def render_index
  cards = PHENOTYPES.map do |key, phenotype|
    group_label = GROUP_META.fetch(GROUP_BY_KEY.fetch(key)).fetch(:label)
    <<~HTML
      <a class="sap-card sap-index-card" href="./#{slug_for_key(key)}.html" data-search="#{h([phenotype.fetch(:animal_name), phenotype.fetch(:title), group_label].join(" ").downcase)}">
        <img src="#{h(local_or_placeholder_image_path(phenotype))}" alt="#{h(phenotype.fetch(:animal_name))} sleep animal illustration" loading="lazy" />
        <div class="sap-card-copy">
          <p class="sap-mini-label">#{h(group_label)}</p>
          <h3>#{h(phenotype.fetch(:animal_name))}</h3>
          <p>#{h(phenotype.fetch(:title))}</p>
          <p class="sap-card-hook">#{h(phenotype.fetch(:hook))}</p>
        </div>
      </a>
    HTML
  end.join

  body = <<~HTML
    <div class="sap-page">
      <header class="sap-shell sap-topbar">
        <a class="sap-brand" href="./index.html">Sleep Animal Pages</a>
        <nav class="sap-nav">
          <a href="./index.html">Catalog</a>
          <a href="https://app.sleepspace.com/users/sign_up">SleepSpace Quiz</a>
          <a href="https://sleepspace.com/science">Science</a>
          <a href="https://sleepspace.com/learn-about-sleep/">Articles</a>
        </nav>
      </header>

      <main>
        <section class="sap-shell sap-hero sap-index-hero">
          <div class="sap-hero-copy">
            <p class="sap-eyebrow">Long-form rebuild</p>
            <h1>#{PHENOTYPES.size} detailed sleep animal webpages with citations</h1>
            <p class="sap-lede">
              These pages were regenerated from the local phenotype source, then expanded with phenotype-specific papers, PubMed and official sleep-health references,
              and SleepSpace article links gathered from sleepspace.com.
            </p>
            <p>
              Where SleepSpace already had suitable imagery, those images were reused. Where the project or site library did not contain a matching animal,
              placeholder illustrations remain in place so every page is still visually complete. Each page now carries a keyword mesh derived from the sources actually used on that page.
            </p>
            <div class="sap-button-row">
              <a class="sap-button sap-button-primary" href="https://app.sleepspace.com/users/sign_up">Take the SleepSpace quiz</a>
              <a class="sap-button sap-button-secondary" href="https://sleepspace.com/learn-about-sleep/">Browse SleepSpace articles</a>
            </div>
          </div>
          <div class="sap-hero-visual">
            <figure class="sap-card sap-hero-image">
              <img src="#{h(SPIDER_IMAGES.fetch(:bedside))}" alt="SleepSpace bedside image from sleepspace.com" />
            </figure>
            <div class="sap-hero-stack">
              <figure class="sap-card sap-mini-visual">
                <img src="#{h(SPIDER_IMAGES.fetch(:footer))}" alt="SleepSpace app and watch image from sleepspace.com" loading="lazy" />
              </figure>
              <figure class="sap-card sap-mini-visual">
                <img src="#{h(SPIDER_IMAGES.fetch(:wearables))}" alt="SleepSpace wearables visual" loading="lazy" />
              </figure>
            </div>
          </div>
        </section>

        <section class="sap-shell sap-section">
          <div class="sap-section-heading">
            <p class="sap-eyebrow">Catalog</p>
            <h2>Browse all #{PHENOTYPES.size} long-form phenotype pages</h2>
          </div>
          <div class="sap-toolbar">
            <label class="sap-search">
              <span>Search by animal, title, or group</span>
              <input id="sap-search-input" type="search" placeholder="Try delayed clock, snoring, stress, grief, shift work..." />
            </label>
          </div>
          <div class="sap-grid sap-index-grid">#{cards}</div>
        </section>
      </main>
    </div>
    <script>
      const searchInput = document.getElementById('sap-search-input');
      const cards = Array.from(document.querySelectorAll('.sap-index-card'));
      searchInput?.addEventListener('input', () => {
        const query = searchInput.value.trim().toLowerCase();
        cards.forEach((card) => {
          const visible = (card.dataset.search || '').includes(query);
          card.style.display = visible ? '' : 'none';
        });
      });
    </script>
  HTML

  render_html(
    title: "Sleep Animal Pages Catalog",
    description: "A catalog of #{PHENOTYPES.size} detailed evidence-backed SleepSpace-inspired sleep animal webpages.",
    body: body
  )
end

PHENOTYPES.each do |key, phenotype|
  File.write(File.join(OUTPUT_DIR, "#{slug_for_key(key)}.html"), render_page(key, phenotype))
end

File.write(File.join(OUTPUT_DIR, "index.html"), render_index)

puts "Generated #{PHENOTYPES.size} detailed sleep animal pages in #{OUTPUT_DIR}"
