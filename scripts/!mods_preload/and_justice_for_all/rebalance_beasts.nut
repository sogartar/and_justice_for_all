local beastsOnAnySkillUsed = function(_skill, _targetEntity, _properties) {
  if (_skill == this) {
    _properties.DamageTotalMult *= this.Const.Ajfa.BeastsDamageMult;
  }
};

::ajfa.rebalanceBeasts <- function() {
  this.Const.Ajfa.BeastsDamageMult <- 0.95;
  local skills = [
    "skills/actives/hyena_bite_skill",
    "skills/actives/ghoul_claws",
    "skills/actives/gore_skill",
    "skills/actives/gorge_skill",
    "skills/actives/kraken_bite_skill",
    "skills/actives/nightmare_skill",
    "skills/actives/serpent_bite_skill",
    "skills/actives/spider_bite_skill",
    "skills/actives/sweep_skill",
    //"skills/actives/swallow_whole_skill",
    "skills/actives/tail_slam_skill",
    "skills/actives/tail_slam_big_skill",
    "skills/actives/tail_slam_split_skill",
    "skills/actives/tail_slam_zoc_skill",
    "skills/actives/uproot_small_skill",
    "skills/actives/uproot_skill",
    "skills/actives/wardog_bite",
    "skills/actives/warhound_bite",
    "skills/actives/werewolf_bite",
    "skills/racial/throw_golem_skill",
    "skills/racial/headbutt_skill",
  ];

  foreach(skill in skills) {
    ::mods_hookClass(skill, function(c) {
      local isOnAnySkillUsedInClass = "onAnySkillUsed" in c;
      local onAnySkillUsed;
      if (isOnAnySkillUsedInClass) {
        onAnySkillUsed = c.onAnySkillUsed;
      }
      c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
        if (isOnAnySkillUsedInClass) {
          onAnySkillUsed(_skill, _targetEntity, _properties);
        }
        beastsOnAnySkillUsed(_skill, _targetEntity, _properties);
      };
    }, false, false);
  }

  ::mods_hookClass("skills/actives/nightmare_skill", function(c) {
    c.getDamage = function(_actor) {
      return this.Const.Ajfa.BeastsDamageMult *
        this.Math.max(5, 25 - this.Math.floor(_actor.getCurrentProperties().getBravery() * 0.25));
    };
  }, false, false);
};
