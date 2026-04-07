var ssSleepAnimalGroups = [
  {
    name: "Insomnia and Fragmentation",
    items: [
      { animal: "Cheetah", title: "High-Performance Insomniac", hook: "Your brain runs at full speed, even when your body is ready for bed." },
      { animal: "Firefly", title: "Sleep-Onset Spinner", hook: "You feel tired, but your system does not flip fully into sleep mode." },
      { animal: "Mouse", title: "Anxious Sleeper", hook: "Your mind gets louder when the room gets quiet." },
      { animal: "Rabbit", title: "Featherlight Sleeper", hook: "Sleep comes, but it stays close to the surface." },
      { animal: "Frog", title: "2 AM Waker", hook: "Falling asleep may not be the problem. Staying asleep is." },
      { animal: "Sparrow", title: "Too-Early Riser", hook: "Your body clock may be ending the night before you are done recovering." },
      { animal: "Cat", title: "Napper Rebounder", hook: "Your system is trying to recover wherever it can." },
      { animal: "Weasel", title: "Fragmented Ruminator", hook: "Your sleep keeps getting interrupted by a mind that reopens the day." }
    ]
  },
  {
    name: "Circadian and Schedule",
    items: [
      { animal: "Owl", title: "True Night Owl", hook: "You are not broken. Your clock simply runs later." },
      { animal: "Lark", title: "Morning Sprinter", hook: "Your energy wants to arrive early and be used early." },
      { animal: "Fox", title: "Irregular Schedule Sleeper", hook: "Your sleep is adapting to a moving target." },
      { animal: "Gazelle", title: "Jet-Lag Hopper", hook: "You may be sleeping in multiple time zones, even when your body is still in the last one." },
      { animal: "Bat", title: "Shift Worker", hook: "Your sleep has to perform under conditions biology did not design for." },
      { animal: "Wolf", title: "Delayed Clock", hook: "Your biology is pulling the night later than your life comfortably allows." },
      { animal: "Eagle", title: "Advanced Clock", hook: "Your internal morning may be arriving before your ideal schedule does." },
      { animal: "Mole", title: "Free-Running Clock", hook: "Your schedule signal may be drifting enough that your body clock is hard to pin down." }
    ]
  },
  {
    name: "Quantity and Life Constraints",
    items: [
      { animal: "Horse", title: "Workhorse Sleeper", hook: "Your main sleep problem may not be sleep. It may be time." },
      { animal: "Camel", title: "Sleep Debt Carrier", hook: "You have become good at functioning on less sleep than your body actually wants." },
      { animal: "Kangaroo", title: "New Parent Sleeper", hook: "Your sleep is being asked to stay protective, flexible, and interrupted all at once." },
      { animal: "Goat", title: "Caregiver Sleeper", hook: "Your sleep is carrying more than your own needs." },
      { animal: "Crow", title: "Long-Commuter Sleeper", hook: "Your days may be stealing from your nights." },
      { animal: "Duck", title: "Sandwich-Generation Sleeper", hook: "Your nights are being squeezed from more than one direction." },
      { animal: "Ant", title: "Overtime Grinder", hook: "Your sleep is being compressed by sustained output, not by lack of sleep ability." },
      { animal: "Mule", title: "Heavy-Load Sleeper", hook: "You are carrying enough daily load that sleep has become part recovery, part survival." }
    ]
  },
  {
    name: "Airway, Environment, and Physical Disruption",
    items: [
      { animal: "Bulldog", title: "Airway Clencher", hook: "Your sleep may be getting disrupted by breathing, snoring, or nighttime airway strain." },
      { animal: "Walrus", title: "Thunder Snorer", hook: "Snoring may be the loud symptom of a quieter quality problem." },
      { animal: "Porcupine", title: "Pain Tosser", hook: "Your body may be interrupting your sleep before your brain gets the chance to settle." },
      { animal: "Meerkat", title: "Noise Guard", hook: "Your sleep stays on alert for the next disturbance." },
      { animal: "Penguin", title: "Partner-Poked Sleeper", hook: "Your sleep may be shaped by whoever or whatever shares the night with you." },
      { animal: "Lizard", title: "Heat Kicker", hook: "Your nights may be getting interrupted by temperature, sweating, or heat buildup." },
      { animal: "Armadillo", title: "Restless-Legs Sleeper", hook: "Your body may be asking you to move right when you want it to settle." },
      { animal: "Whale", title: "Altitude Breather", hook: "Your nights may feel lighter or more broken when oxygen and pressure cues change." }
    ]
  },
  {
    name: "Nonrestorative Sleep and Optimization",
    items: [
      { animal: "Dolphin", title: "Half-Awake Sleeper", hook: "You are sleeping enough on paper, but not waking up as restored as you should." },
      { animal: "Hawk", title: "Precision Performer", hook: "You are already functioning, but you want your sleep to sharpen performance." },
      { animal: "Otter", title: "Balanced Builder", hook: "You already have a workable foundation. Now it is about refinement." },
      { animal: "Koala", title: "Long-Sleep Restorer", hook: "Your body may simply need more time asleep than average to feel fully recharged." },
      { animal: "Elephant", title: "Short-Sleep Ace", hook: "You may naturally operate well on less sleep than most people." },
      { animal: "Bear", title: "Consistent Restorer", hook: "You have the kind of sleep foundation most people are trying to build." },
      { animal: "Dog", title: "Flexible Sleeper", hook: "Your sleep appears resilient, adaptable, and generally healthy." }
    ]
  },
  {
    name: "Neuropsych and Complex Sleep Profiles",
    items: [
      { animal: "Peacock", title: "Sleep-Paralysis Sleeper", hook: "Some of your most unsettling sleep experiences may be happening at the edges of sleep itself." },
      { animal: "Shark", title: "Half-Alert Sleeper", hook: "Your nights seem to stay partially watchful instead of fully off duty." },
      { animal: "Platypus", title: "Dream Actor", hook: "Your dreaming system may sometimes be crossing into movement or action." },
      { animal: "Monkey", title: "Intense Dream Sleeper", hook: "Your nights may feel crowded with vivid, memorable, or emotionally loaded dreaming." },
      { animal: "Turtle", title: "Slow-Starter Sleeper", hook: "Your sleep may end, but your system does not feel fully online right away." },
      { animal: "Phoenix", title: "Rebound Sleeper", hook: "Your body is trying to recover in bursts after too much accumulated loss." },
      { animal: "Bee", title: "Stress-Sensitive Sleeper", hook: "Your sleep changes quickly when stress levels rise." },
      { animal: "Ostrich", title: "Escape Sleeper", hook: "Bedtime may carry enough stress that part of you wants to avoid it." }
    ]
  },
  {
    name: "Special Overlap Profiles A",
    items: [
      { animal: "Bison", title: "Apnea-Insomnia Overlap", hook: "Your nights may combine airway strain with trouble falling asleep or settling back down." },
      { animal: "Crab", title: "Back-Sleeper Breather", hook: "Your sleep may worsen when position changes what your airway has to work against." },
      { animal: "Rhino", title: "Explosive Snorer", hook: "The volume and force of your snoring may point to a bigger quality issue than it seems." },
      { animal: "Alligator", title: "Bruxing Breather", hook: "Teeth grinding and breathing strain may be showing up together at night." },
      { animal: "Boar", title: "Alcohol-Airway Sleeper", hook: "Your nights may be getting lighter or noisier when alcohol compounds airway load." },
      { animal: "Goose", title: "Self-Snore Waker", hook: "Your own snoring may be loud enough to break the night apart." },
      { animal: "Moose", title: "Positional Breather", hook: "Your breathing and sleep quality may change substantially with how you sleep." },
      { animal: "Sea Lion", title: "Central Breather", hook: "Your breathing-related sleep disruption may not fit the usual snoring-first pattern." }
    ]
  },
  {
    name: "Special Overlap Profiles B",
    items: [
      { animal: "Seal", title: "Seasonal Adapter", hook: "Your sleep seems to change when light, season, or environment shifts around you." },
      { animal: "Sloth", title: "High-Sleep-Need Sleeper", hook: "Your system may need a meaningfully larger sleep window to feel truly restored." },
      { animal: "Jaguar", title: "Evening Performer", hook: "Your strongest performance energy may come online later than most schedules expect." },
      { animal: "Hummingbird", title: "Micro-Recovery Sleeper", hook: "Your system may be surviving on short, fragmented bursts of recovery instead of one steady night." },
      { animal: "Raccoon", title: "Night Worker", hook: "Your sleep has to recover from work that happens when most people are asleep." },
      { animal: "Swallow", title: "Frequent-Traveler Sleeper", hook: "Your sleep may never fully settle before the next trip asks it to change again." },
      { animal: "Vulture", title: "Grief Sleeper", hook: "Your sleep may be carrying loss, not just fatigue." },
      { animal: "Squirrel", title: "Stress-Triggered Sleeper", hook: "Your sleep may be mostly fine until stress flips the switch." }
    ]
  },
  {
    name: "Foundation Profile",
    items: [
      { animal: "Octopus", title: "Versatile Sleeper", hook: "Your sleep does not fit neatly into one obvious bucket yet." }
    ]
  }
];

(function () {
  var searchInput = document.querySelector("#ss-animal-search");
  var groupsContainer = document.querySelector("#ss-animal-groups");

  function makeWhiteTransparent(img) {
    function process() {
      var canvas = document.createElement("canvas");
      var context = canvas.getContext("2d");
      var width = img.naturalWidth || img.width;
      var height = img.naturalHeight || img.height;
      var imageData;
      var pixels;
      var i;

      if (!width || !height || !context) return;

      canvas.width = width;
      canvas.height = height;
      context.drawImage(img, 0, 0, width, height);
      imageData = context.getImageData(0, 0, width, height);
      pixels = imageData.data;

      for (i = 0; i < pixels.length; i += 4) {
        if (pixels[i] > 245 && pixels[i + 1] > 245 && pixels[i + 2] > 245) {
          pixels[i + 3] = 0;
        }
      }

      context.putImageData(imageData, 0, 0);
      img.src = canvas.toDataURL("image/png");
    }

    if (img.complete) process();
    else img.addEventListener("load", process, { once: true });
  }

  function renderGroups(query) {
    var normalized = (query || "").trim().toLowerCase();
    var html = ssSleepAnimalGroups.map(function (group, index) {
      var matches = group.items.filter(function (item) {
        var haystack = (item.animal + " " + item.title + " " + item.hook + " " + group.name).toLowerCase();
        return haystack.indexOf(normalized) !== -1;
      });

      if (!matches.length) return "";

      return (
        '<details class="ss-animal-group" ' + ((normalized || index === 0) ? "open" : "") + ">" +
          "<summary><span>" + group.name + "</span><span>" + matches.length + " profile" + (matches.length === 1 ? "" : "s") + "</span></summary>" +
          '<div class="ss-animal-group-grid">' +
            matches.map(function (item) {
              return (
                '<article class="ss-taxonomy-card">' +
                  '<span class="ss-taxonomy-animal-name">' + item.animal + "</span>" +
                  "<h3>" + item.title + "</h3>" +
                  "<p>" + item.hook + "</p>" +
                "</article>"
              );
            }).join("") +
          "</div>" +
        "</details>"
      );
    }).join("");

    groupsContainer.innerHTML = html || '<div class="ss-taxonomy-empty">No sleep animals matched that search. Try keywords like insomnia, schedule, snoring, shift, stress, caregiver, or jet lag.</div>';
  }

  if (groupsContainer) renderGroups("");

  if (searchInput) {
    searchInput.addEventListener("input", function (event) {
      renderGroups(event.target.value);
    });
  }

  Array.prototype.forEach.call(
    document.querySelectorAll('.ss-sleep-animal-page img[data-make-transparent="true"]'),
    function (img) { makeWhiteTransparent(img); }
  );
})();
