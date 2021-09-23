::mods_registerMod("and_justice_for_all", 1.0.0, "and_justice_for_all");

local gt = this.getroottable();

if (!("ajfa" in gt)) {
  ::ajfa <- {};
}

local setupRootTableStructure = function() {
  gt.Ajfa <- {};
  gt.Const.Ajfa <- {};
};

local buffAttributesLeveling = function() {
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Hitpoints].Max += 2;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Fatigue].Max += 2;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Bravery].Max += 2;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Initiative].Max += 2;

  gt.Const.Ajfa.AttributeLevelUpTalentBonus <- [2, 2, 2, 2, 1, 1, 1, 1];
  
  ::mods_hookExactClass("entity/tactical/player", function(c) {
    c.fillAttributeLevelUpValues = function(_amount, _maxOnly = false, _minOnly = false) {
      if (this.m.Attributes.len() == 0) {
        this.m.Attributes.resize(this.Const.Attributes.COUNT);
  
        for(local i = 0; i != this.Const.Attributes.COUNT; i = ++i) {
          this.m.Attributes[i] = [];
        }
      }
  
      for(local i = 0; i != this.Const.Attributes.COUNT; i = ++i) {
        for(local j = 0; j < _amount; j = ++j) {
          if (_minOnly) {
            this.m.Attributes[i].insert(0, 1);
          }
          else if (_maxOnly) {
            this.m.Attributes[i].insert(0, this.Const.AttributesLevelUp[i].Max);
          }
          else {
            this.m.Attributes[i].insert(0, this.Math.rand(
              this.Const.AttributesLevelUp[i].Min + (this.m.Talents[i] == 3 ? 2 : this.m.Talents[i]) * this.Const.Ajfa.AttributeLevelUpTalentBonus[i],
              this.Const.AttributesLevelUp[i].Max + (this.m.Talents[i] == 3 ? 1 : 0) * this.Const.Ajfa.AttributeLevelUpTalentBonus[i]));
          }
        }
      }
    };
  });
};

local nerfColossus = function() {
  gt.Const.Ajfa.ColossusHitpointsMult <- 1.20;
  gt.Const.Strings.PerkDescription.Colossus = "Bring it on! Hitpoints are increased by [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.ColossusHitpointsMult - 1) * 100) + "%[/color], which also reduces the chance to sustain debilitating injuries when being hit.";

  ::mods_hookClass("skills/perks/perk_colossus", function(c) {
    c = ::mods_getClassForOverride(c, "perk_colossus");
    c.onAdded = function() {
      local actor = this.getContainer().getActor();

      if (actor.getHitpoints() == actor.getHitpointsMax()) {
        actor.setHitpoints(this.Math.floor(actor.getHitpoints() * this.Const.Ajfa.ColossusHitpointsMult));
      }
    };

    c.onUpdate = function(_properties) {
      _properties.HitpointsMult *= this.Const.Ajfa.ColossusHitpointsMult;
    }
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.colossus");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.Colossus;
};

local buffBullseye = function() {
  gt.Const.Ajfa.BullseyeRangedAttackBlockedChanceMult <- 0.533;
  local total = this.Const.Combat.RangedAttackBlockedChance * gt.Const.Ajfa.BullseyeRangedAttackBlockedChanceMult;
  gt.Const.Strings.PerkDescription.Bullseye = "Nailed it! The penalty to hitchance when shooting at a target you have no clear line of fire to is reduced from [color=" +
    this.Const.UI.Color.NegativeValue + "]" + this.Math.round(this.Const.Combat.RangedAttackBlockedChance * 100) +
    "%[/color] to [color=" + this.Const.UI.Color.NegativeValue + "]" + this.Math.round(total * 100) + "%[/color] for ranged weapons.";

  ::mods_hookClass("skills/perks/perk_bullseye", function(c) {
    c = ::mods_getClassForOverride(c, "perk_bullseye");
    c.m.RangedAttackBlockedChanceMult <- this.Const.Ajfa.BullseyeRangedAttackBlockedChanceMult;
    c.onUpdate = function(_properties) {
      _properties.RangedAttackBlockedChanceMult *= this.m.RangedAttackBlockedChanceMult;
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.bullseye");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.Bullseye;
}

local nerfGifted = function() {
  gt.Const.Strings.PerkDescription.Gifted =
    "Mercenary life comes easy when you\'re naturally gifted. Instantly gain a levelup to increase this character\'s attributes.";
  ::mods_hookClass("skills/perks/perk_gifted", function(c) {
    c = ::mods_getClassForOverride(c, "perk_gifted");
    c.onAdded = function() {
      if (!this.m.IsApplied) {
        this.m.IsApplied = true;
        local actor = this.getContainer().getActor();
        actor.m.LevelUps += 1;
        actor.fillAttributeLevelUpValues(1);
      }
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.gifted");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.Gifted;
}

local nerfThrowingMastery = function() {
  gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance2 <- 1.13;
  gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance3 <- 1.07;
  gt.Const.Strings.PerkDescription.SpecThrowing = "Master throwing weapons to wound or kill the enemy before they even get close. " +
    "Skills build up [color=" + this.Const.UI.Color.NegativeValue + "]25%[/color] less Fatigue." +
    "\n\nDamage is increased by [color=" + this.Const.UI.Color.PositiveValue + "]" + this.Math.round((gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance2 - 1) * 100) + "%[/color] when attacking at 2 tiles of distance." +
    "\n\nDamage is increased by [color=" + this.Const.UI.Color.PositiveValue + "]" + this.Math.round((gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance3 - 1) * 100) + "%[/color] when attacking at 3 tiles of distance.",

  ::mods_hookClass("skills/perks/perk_mastery_throwing", function(c) {
    c = ::mods_getClassForOverride(c, "perk_mastery_throwing");
    c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
      if (_targetEntity == null)
      {
        return;
      }

      if (_skill.isRanged() && (_skill.getID() == "actives.throw_axe" || _skill.getID() == "actives.throw_balls" || _skill.getID() == "actives.throw_javelin" || _skill.getID() == "actives.throw_spear" || _skill.getID() == "actives.sling_stone"))
      {
        local d = this.getContainer().getActor().getTile().getDistanceTo(_targetEntity.getTile());

        if (d <= 2)
        {
          _properties.DamageTotalMult *= this.Const.Ajfa.ThrowingMasteryDamageMultAtDistance2;
        }
        else if (d <= 3)
        {
          _properties.DamageTotalMult *= gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance3;
        }
      }
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.mastery.throwing");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.SpecThrowing;
};

local buffThrowingWithoutMastery = function() {
  ::mods_hookDescendants("entity/tactical/actor", function(c) {
    local actorClass = ::mods_getClassForOverride(c, "actor");
    if (!("onInitOriginalBuffThrowingWithoutMastery" in actorClass)) {
      actorClass.onInitOriginalBuffThrowingWithoutMastery <- actorClass.onInit;
      actorClass.onInit = function() {
        this.onInitOriginalBuffThrowingWithoutMastery();
        this.m.Skills.add(this.new("scripts/skills/special/ajfa_buff_throwing"));
      };
    }
  });
};

local buffCripplingStrikes = function() {
  gt.Const.Ajfa.CripplingStrikesThresholdToInflictInjuryMult <- 0.6;
  gt.Const.Strings.PerkDescription.CripplingStrikes =
    "Cripple your enemies! Lowers the threshold to inflict injuries by [color=" +
    this.Const.UI.Color.NegativeValue + "]" +
    this.Math.round((1 - gt.Const.Ajfa.CripplingStrikesThresholdToInflictInjuryMult) * 100) +
    "%[/color] for both melee and ranged attacks.";

  ::mods_hookClass("skills/perks/perk_crippling_strikes", function(c) {
    c = ::mods_getClassForOverride(c, "perk_crippling_strikes");
    c.onUpdate = function(_properties) {
      _properties.ThresholdToInflictInjuryMult *= this.Const.Ajfa.CripplingStrikesThresholdToInflictInjuryMult;
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.crippling_strikes");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.CripplingStrikes;
};

local buffNineLives = function() {
  gt.Const.Ajfa.NineLivesMeleeDefenseModifier <- 20;
  gt.Const.Ajfa.NineLivesRangedDefenseModifier <- 20;
  gt.Const.Ajfa.NineLivesBraveryModifier <- 20;
  gt.Const.Ajfa.NineLivesInitiativeModifier <- 20;
  gt.Const.Ajfa.NineLivesEffectTurns <- 2;

  gt.Const.Strings.PerkDescription.NineLives =
    "Once per battle, upon receiving a killing blow, survive instead with a few hitpoints left" +
    " and have all damage over time effects (e.g. bleeding, poisoned) cured." +
    " The next hit is likely to kill you for good, of course," +
    " but improved defensive stats for " + gt.Const.Ajfa.NineLivesEffectTurns +
    " turns help you to survive until then.";

  local perkConsts = ::libreuse.findPerkConsts("perk.nine_lives");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.NineLives;

  ::mods_hookClass("skills/effects/nine_lives_effect", function(c) {
   c = ::mods_getClassForOverride(c, "nine_lives_effect");
   c.getTooltip = function() {
     return [
       {
         id = 1,
         type = "title",
         text = this.getName()
       },
       {
         id = 2,
         type = "description",
         text = this.getDescription()
       },
       {
         id = 10,
         type = "text",
         icon = "ui/icons/melee_defense.png",
         text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Const.Ajfa.NineLivesMeleeDefenseModifier + "[/color] Melee Defense"
       },
       {
         id = 11,
         type = "text",
         icon = "ui/icons/ranged_defense.png",
         text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Const.Ajfa.NineLivesRangedDefenseModifier + "[/color] Ranged Defense"
       },
       {
         id = 11,
         type = "text",
         icon = "ui/icons/bravery.png",
         text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Const.Ajfa.NineLivesBraveryModifier + "[/color] Resolve"
       },
       {
         id = 11,
         type = "text",
         icon = "ui/icons/initiative.png",
         text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Const.Ajfa.NineLivesInitiativeModifier + "[/color] Initiative"
       }
     ];
   };

    c.onUpdate = function(_properties) {
      _properties.MeleeDefense += this.Const.Ajfa.NineLivesMeleeDefenseModifier;
      _properties.RangedDefense += this.Const.Ajfa.NineLivesRangedDefenseModifier;
      _properties.Bravery += this.Const.Ajfa.NineLivesBraveryModifier;
      _properties.Initiative += this.Const.Ajfa.NineLivesInitiativeModifier;
    };

    c.onTurnStart = function() {
      if (this.m.EffectTurns == this.m.Turns) {
        this.removeSelf()
      } else {
        this.m.Turns++;
      }
    }

    c.getDescription <- function() {
      return "This character seems to have nine lives! Just having had a close encounter with death," +
        " they are in a heightened state of survival for " +
        (this.m.EffectTurns - this.m.Turns + 1) + " turn(s).";
    }
  }, false, false);

  ::mods_hookNewObject("skills/effects/nine_lives_effect", function(o) {
    o.m.EffectTurns <- this.Const.Ajfa.NineLivesEffectTurns;
    o.m.Turns <- 1;
  });
};

local buffCoupDeGrace = function() {
  gt.Const.Ajfa.CoupDeGraceDamageTotalMult <- 1.25;

  gt.Const.Strings.PerkDescription.CoupDeGrace =
    "Inflict additional [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.CoupDeGraceDamageTotalMult - 1) * 100) +
    "%[/color] damage against targets that have sustained any injury effects, like a broken arm.";

  ::mods_hookClass("skills/perks/perk_coup_de_grace", function(c) {
    c = ::mods_getClassForOverride(c, "perk_coup_de_grace");
    c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
      if (_targetEntity == null) {
        return;
      }

      if (_skill.isAttack() && _targetEntity.getSkills().hasSkillOfType(this.Const.SkillType.TemporaryInjury)) {
        _properties.DamageTotalMult *= this.Const.Ajfa.CoupDeGraceDamageTotalMult;
      }
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.coup_de_grace");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.CoupDeGrace;
};

local buffFootwork = function() {
  gt.Const.Ajfa.FootworkFatigueCostModifier <- -5;

  ::mods_hookNewObject("skills/actives/footwork", function(o) {
    o.m.FatigueCost += this.Const.Ajfa.FootworkFatigueCostModifier;
  });
};

local buffFastAdaptation = function() {
  gt.Const.Ajfa.FastAdaptationHitChanceBonusPerStack <- 12;

  gt.Const.Strings.PerkDescription.FastAdaption =
    "Adapt to your opponent\'s moves! Gain an additional stacking [color=" + this.Const.UI.Color.PositiveValue + "]+" +
    gt.Const.Ajfa.FastAdaptationHitChanceBonusPerStack +
    "%[/color] chance to hit with each attack that misses an opponent. Bonus is reset upon landing a hit.";

  ::mods_hookClass("skills/perks/perk_fast_adaption", function(c) {
    c = ::mods_getClassForOverride(c, "perk_fast_adaption");
    c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
      if (this.m.Stacks != 0 && _skill.isAttack()) {
        _properties.MeleeSkill += this.Const.Ajfa.FastAdaptationHitChanceBonusPerStack * this.m.Stacks;
        _properties.RangedSkill += this.Const.Ajfa.FastAdaptationHitChanceBonusPerStack * this.m.Stacks;
      }
    };
    c.getDescription = function() {
      return "This character is adapting fast to their opponent\'s moves and gains an additional [color=" + this.Const.UI.Color.PositiveValue + "]+" + this.m.Stacks * this.Const.Ajfa.FastAdaptationHitChanceBonusPerStack + "%[/color] chance to hit with any attack.";
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.fast_adaption");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.FastAdaption;
};

local buffAdrenaline = function() {
  gt.Const.Ajfa.AdrenalineFatigueCostModifier <- -2;

  ::mods_hookNewObject("skills/actives/adrenaline_skill", function(o) {
    o.m.FatigueCost += this.Const.Ajfa.AdrenalineFatigueCostModifier;
  });
};

local buffHeadHunter = function() {
  gt.Const.Ajfa.HeadHunterHitChanceBonusWhenProked <- 5;
  gt.Const.Strings.PerkDescription.HeadHunter =
    "Go for the head! Hitting the head of a target will give you a guaranteed" +
    " hit to the head also with your next attack and [color=" + this.Const.UI.Color.PositiveValue + "]+" +
    gt.Const.Ajfa.HeadHunterHitChanceBonusWhenProked + "%[/color] hit chance. Connecting with your hit," +
    " or missing with your attack, will reset the effect.";

  local perkConsts = ::libreuse.findPerkConsts("perk.head_hunter");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.HeadHunter;

  ::mods_hookClass("skills/perks/perk_head_hunter", function(c) {
    c = ::mods_getClassForOverride(c, "perk_head_hunter");
    c.onAnySkillUsedAjfaOriginal <- c.onAnySkillUsed;
    c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
      this.onAnySkillUsedAjfaOriginal(_skill, _targetEntity, _properties);
      if (_skill.isAttack() && this.m.Stacks != 0) {
        _properties.MeleeSkill += this.Const.Ajfa.HeadHunterHitChanceBonusWhenProked;
        _properties.RangedSkill += this.Const.Ajfa.HeadHunterHitChanceBonusWhenProked;
      }
    }

    c.getDescription = function() {
      return "This character is guaranteed to land a hit to the head if the next attack connects. [color=" +
        this.Const.UI.Color.PositiveValue + "]+" + this.Const.Ajfa.HeadHunterHitChanceBonusWhenProked +
        "%[/color] hit chance for next attack.";
    };
  }, false, false);
};

local nerfNimble = function() {
  gt.Const.Ajfa.NimbleDamageReceivedRegularBonus <- 0.5;
  gt.Const.Strings.PerkDescription.Nimble = "Specialize in light armor!" +
    " By nimbly dodging or deflecting blows, convert any hits to glancing hits." +
    " Hitpoint damage taken is reduced by up to [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((1 - gt.Const.Ajfa.NimbleDamageReceivedRegularBonus) * 100) + "%[/color]," +
    " but lowered exponentially by the total penalty to Maximum Fatigue from body and head armor" +
    " above [color=" + this.Const.UI.Color.PositiveValue + "]15[/color]." +
    " The lighter your armor and helmet, the more you benefit.\n\n" +
    "Brawny does not affect this perk.\n\nDoes not affect damage from mental attacks or status effects," +
    " but can help to avoid receiving them.";

  local perkConsts = ::libreuse.findPerkConsts("perk.nimble");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.Nimble;

  ::mods_hookClass("skills/perks/perk_nimble", function(c) {
    c = ::mods_getClassForOverride(c, "perk_nimble");
    c.getChance = function() {
      local fat = 0;
      local body = this.getContainer().getActor().getItems().getItemAtSlot(this.Const.ItemSlot.Body);
      local head = this.getContainer().getActor().getItems().getItemAtSlot(this.Const.ItemSlot.Head);

      if (body != null)
      {
        fat = fat + body.getStaminaModifier();
      }

      if (head != null)
      {
        fat = fat + head.getStaminaModifier();
      }

      fat = this.Math.min(0, fat + 15);
      local ret = this.Math.minf(1.0, this.Const.Ajfa.NimbleDamageReceivedRegularBonus +
        this.Math.pow(this.Math.abs(fat), 1.23) * 0.01);
      return ret;
    };
  }, false, false);
};

local nerfBattleForged = function() {
  gt.Const.Ajfa.BattleForgedDamageReceivedArmorBonus <- 0.04;
  gt.Const.Strings.PerkDescription.BattleForged = "Specialize in heavy armor!" +
    " Armor damage taken is reduced by a percentage equal to [color=" +
    this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round(gt.Const.Ajfa.BattleForgedDamageReceivedArmorBonus * 100) +
    "%[/color] of the current total armor value of both body and head armor." +
    " The heavier your armor and helmet, the more you benefit.\n\n" +
    "Does not affect damage from mental attacks or status effects, but can help to avoid receiving them.";

  local perkConsts = ::libreuse.findPerkConsts("perk.battle_forged");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.BattleForged;

  ::mods_hookClass("skills/perks/perk_battle_forged", function(c) {
    c = ::mods_getClassForOverride(c, "perk_battle_forged");
    c.onBeforeDamageReceived = function(_attacker, _skill, _hitInfo, _properties) {
      if (_attacker != null && _attacker.getID() == this.getContainer().getActor().getID() || _skill != null && !_skill.isAttack()) {
        return;
      }

      local armor = this.getContainer().getActor().getArmor(this.Const.BodyPart.Head) + this.getContainer().getActor().getArmor(this.Const.BodyPart.Body);
      _properties.DamageReceivedArmorMult *= 1.0 - armor * this.Const.Ajfa.BattleForgedDamageReceivedArmorBonus * 0.01;
    };

    c.getDescription = function() {
      return "Specialize in heavy armor! Armor damage taken is reduced by a percentage equal to [color=" +
        this.Const.UI.Color.PositiveValue + "]" +
        this.Math.round(this.Const.Ajfa.BattleForgedDamageReceivedArmorBonus * 100) +
        "%[/color] of the current total armor value of both body and head armor." +
        " The heavier your armor and helmet, the more you benefit.";
    };

    c.getTooltip = function() {
      local armor = this.getContainer().getActor().getArmor(this.Const.BodyPart.Head) + this.getContainer().getActor().getArmor(this.Const.BodyPart.Body);
      local fm = this.Math.floor((1.0 - armor * this.Const.Ajfa.BattleForgedDamageReceivedArmorBonus * 0.01) * 100);
      local tooltip = this.skill.getTooltip();

      if (fm < 100) {
        tooltip.push({
          id = 6,
          type = "text",
          icon = "ui/icons/special.png",
          text = "Only receive [color=" + this.Const.UI.Color.PositiveValue + "]" + fm + "%[/color] of any damage to armor from attacks"
        });
      }
      else {
        tooltip.push({
          id = 6,
          type = "text",
          icon = "ui/tooltips/warning.png",
          text = "[color=" + this.Const.UI.Color.NegativeValue + "]This character\'s armor isn\'t protective enough to grant any benefit from having the Battleforged perk[/color]"
        });
      }

      return tooltip;
    }
  }, false, false);
};

local buffTaunt = function() {
  gt.Const.Ajfa.TauntActionPointsCost <- 3;

  ::mods_hookNewObject("skills/actives/taunt", function(o) {
    o.m.ActionPointCost = this.Const.Ajfa.TauntActionPointsCost;
  });
};

local buffBagsAndBelts = function() {
  gt.Const.Ajfa.BagsAndBeltsTowHandedStaminaModifierMult <- 0.5;
  gt.Const.Strings.PerkDescription.BagsAndBelts = "Unlock 2 extra bag slots to carry all your favorite things." +
    " Items placed in bags no longer give a penalty to Maximum Fatigue." +
    " Two-handed weapons placed in bags have their penalty reduced by [color=" +
    this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round(gt.Const.Ajfa.BagsAndBeltsTowHandedStaminaModifierMult * 100) + "%[/color].";

  local perkConsts = ::libreuse.findPerkConsts("perk.bags_and_belts");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.BagsAndBelts;

  ::mods_hookClass("skills/special/bag_fatigue", function(c) {
    c = ::mods_getClassForOverride(c, "bag_fatigue");
    c.onUpdate = function(_properties) {
      local hasBagsAndBelts = this.getContainer().hasSkill("perk.bags_and_belts");
      local items = this.getContainer().getActor().getItems().getAllItemsAtSlot(this.Const.ItemSlot.Bag);

      foreach(item in items) {
        if (item.getBlockedSlotType() != null) {
          _properties.Stamina += (hasBagsAndBelts ? this.Const.Ajfa.BagsAndBeltsTowHandedStaminaModifierMult : 1.0) *
            item.getStaminaModifier() / 2;
        } else {
          _properties.Stamina += (hasBagsAndBelts ? 0 : item.getStaminaModifier() / 2);
        }
      }
    };
  }, false, false);
};

local nerfPolearmMastery = function() {
  gt.Const.Ajfa.PolearmMasteryFatigueCostMult <- 0.84;
  gt.Const.Strings.PerkDescription.SpecPolearm = "Master polearms and keeping the enemy at bay." +
    " Skills build up [color=" + this.Const.UI.Color.NegativeValue + "]" +
    this.Math.round((1 - gt.Const.Ajfa.PolearmMasteryFatigueCostMult) * 100) + "%[/color] less Fatigue.\n\n" +
    "Polearm skills have their Action Point cost reduced to [color=" + this.Const.UI.Color.NegativeValue + "]5[/color]," +
    " and no longer have a penalty for attacking targets directly adjacent.";

  local perkConsts = ::libreuse.findPerkConsts("perk.mastery.polearm");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.SpecPolearm;

  local onAfterUpdateNew = function(_properties) {
    this.m.FatigueCostMult = _properties.IsSpecializedInPolearms ? this.Const.Ajfa.PolearmMasteryFatigueCostMult : 1.0;
    this.m.ActionPointCost = _properties.IsSpecializedInPolearms ? 5 : 6;
  };

  ::mods_hookClass("skills/actives/hook", function(c) {
    c = ::mods_getClassForOverride(c, "hook");
    c.onAfterUpdate = onAfterUpdateNew;
  }, false, false);

  ::mods_hookClass("skills/actives/impale", function(c) {
    c = ::mods_getClassForOverride(c, "impale");
    c.onAfterUpdate = onAfterUpdateNew;
  }, false, false);

  ::mods_hookClass("skills/actives/reap_skill", function(c) {
    c = ::mods_getClassForOverride(c, "reap_skill");
    c.onAfterUpdate = onAfterUpdateNew;
  }, false, false);

  ::mods_hookClass("skills/actives/repel", function(c) {
    c = ::mods_getClassForOverride(c, "repel");
    c.onAfterUpdate = onAfterUpdateNew;
  }, false, false);

  ::mods_hookClass("skills/actives/rupture", function(c) {
    c = ::mods_getClassForOverride(c, "rupture");
    c.onAfterUpdate = function(_properties) {
      this.m.FatigueCostMult = _properties.IsSpecializedInPolearms ? this.Const.Ajfa.PolearmMasteryFatigueCostMult : 1.0;
    }
  }, false, false);

  ::mods_hookClass("skills/actives/strike_skill", function(c) {
    c = ::mods_getClassForOverride(c, "strike_skill");
    c.onAfterUpdate = function(_properties) {
      if (this.m.ApplyAxeMastery) {
        this.m.FatigueCostMult = _properties.IsSpecializedInAxes ? this.Const.Combat.WeaponSpecFatigueMult : 1.0;
      } else {
        onAfterUpdateNew(_properties);
      }
    };
  }, false, false);
};

local buffAnticipation = function() {
  gt.Const.Ajfa.AnticipationRangedDefensePerTileFlatBonus <- 1;
  gt.Const.Ajfa.AnticipationRangedDefensePerTileMultBonus <- 0.15;
  gt.Const.Ajfa.AnticipationRangedDefenseMinBonus <- 10;
  gt.Const.Strings.PerkDescription.Anticipation =
    "When being attacked with ranged weapons, gain [color=" +
    this.Const.UI.Color.PositiveValue + "]" + gt.Const.Ajfa.AnticipationRangedDefensePerTileFlatBonus +
    " + " + this.Math.round(gt.Const.Ajfa.AnticipationRangedDefensePerTileMultBonus * 100) +
    "%[/color] of your base Ranged Defense as additional Ranged Defense per tile that the attacker is away," +
    " and always at least [color=" + this.Const.UI.Color.PositiveValue + "]+" +
    gt.Const.Ajfa.AnticipationRangedDefenseMinBonus + "[/color] to Ranged Defense.";

  local perkConsts = ::libreuse.findPerkConsts("perk.anticipation");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.Anticipation;

  ::mods_hookClass("skills/perks/perk_anticipation", function(c) {
    c = ::mods_getClassForOverride(c, "perk_anticipation");
    c.onBeingAttacked = function(_attacker, _skill, _properties) {
      local dist = _attacker.getTile().getDistanceTo(this.getContainer().getActor().getTile());
      _properties.RangedDefense += this.Math.max(this.Const.Ajfa.AnticipationRangedDefenseMinBonus,
      this.Math.floor(dist * (this.Const.Ajfa.AnticipationRangedDefensePerTileFlatBonus +
      this.getContainer().getActor().getBaseProperties().getRangedDefense() *
      this.Const.Ajfa.AnticipationRangedDefensePerTileMultBonus)));
    };
  }, false, false);
};

local nerfFortifiedMind = function() {
  gt.Const.Ajfa.FortifiedMindBraveryMult <- 1.20;
  gt.Const.Strings.PerkDescription.FortifiedMind =
    "An iron will is not swayed from the true path easily." +
    " Resolve is increased by [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.FortifiedMindBraveryMult - 1) * 100) + "%[/color].";

  local perkConsts = ::libreuse.findPerkConsts("perk.fortified_mind");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.FortifiedMind;

  ::mods_hookClass("skills/perks/perk_fortified_mind", function(c) {
    c = ::mods_getClassForOverride(c, "perk_fortified_mind");
    c.onUpdate = function(_properties) {
      _properties.BraveryMult *= this.Const.Ajfa.FortifiedMindBraveryMult;
    };
  }, false, false);
};

local nerfLoneWolf = function() {
  gt.Const.Ajfa.LoneWolfMeleeSkillMult <- 1.15;
  gt.Const.Ajfa.LoneWolfRangedSkillMult <- 1.15;
  gt.Const.Ajfa.LoneWolfMeleeDefenseMult <- 1.15;
  gt.Const.Ajfa.LoneWolRangedDefenseMult <- 1.15;
  gt.Const.Ajfa.LoneWolfBraveryMult <- 1.10;
  gt.Const.Strings.PerkDescription.LoneWolf =
    "I work best alone. With no ally within 3 tiles of distance, gain a" +
    " [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.LoneWolfMeleeSkillMult - 1) * 100) + "%[/color] bonus to Melee Skill," +
    " [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.LoneWolfRangedSkillMult - 1) * 100) + "%[/color] bonus to Ranged Skill," +
    " [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.LoneWolfMeleeDefenseMult - 1) * 100) + "%[/color] bonus to Melee Defense," +
    " [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.LoneWolRangedDefenseMult - 1) * 100) + "%[/color] bonus to Ranged Defense and" +
    " [color=" + this.Const.UI.Color.PositiveValue + "]" +
    this.Math.round((gt.Const.Ajfa.LoneWolfBraveryMult - 1) * 100) + "%[/color] bonus to Resolve.";

  local perkConsts = ::libreuse.findPerkConsts("perk.lone_wolf");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.LoneWolf;

  ::mods_hookClass("skills/effects/lone_wolf_effect", function(c) {
    c = ::mods_getClassForOverride(c, "lone_wolf_effect");
    c.onUpdate = function(_properties) {
      if (!this.getContainer().getActor().isPlacedOnMap()) {
        this.m.IsHidden = true;
        return;
      }

      local actor = this.getContainer().getActor();
      local myTile = actor.getTile();
      local allies = this.Tactical.Entities.getInstancesOfFaction(actor.getFaction());
      local isAlone = true;

      foreach(ally in allies) {
        if (ally.getID() == actor.getID() || !ally.isPlacedOnMap()) {
          continue;
        }

        if (ally.getTile().getDistanceTo(myTile) <= 3) {
            isAlone = false;
          break;
        }
      }

      if (isAlone) {
        this.m.IsHidden = false;
        _properties.MeleeSkillMult *= this.Const.Ajfa.LoneWolfMeleeSkillMult;
        _properties.RangedSkillMult *= this.Const.Ajfa.LoneWolfRangedSkillMult;
        _properties.MeleeDefenseMult *= this.Const.Ajfa.LoneWolfMeleeDefenseMult;
        _properties.RangedDefenseMult *= this.Const.Ajfa.LoneWolRangedDefenseMult;
        _properties.BraveryMult *= this.Const.Ajfa.LoneWolfBraveryMult;
      }
      else {
        this.m.IsHidden = true;
      }
    };

    c.getTooltip = function() {
      return [
        {
            id = 1,
            type = "title",
            text = this.getName()
        },
        {
          id = 2,
          type = "description",
          text = this.getDescription()
        },
        {
          id = 10,
          type = "text",
          icon = "ui/icons/melee_skill.png",
          text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" +
            this.Math.round((this.Const.Ajfa.LoneWolfMeleeSkillMult - 1) * 100) + "%[/color] Melee Skill"
        },
        {
          id = 10,
          type = "text",
          icon = "ui/icons/ranged_skill.png",
          text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" +
            this.Math.round((this.Const.Ajfa.LoneWolfRangedSkillMult - 1) * 100) + "%[/color] Ranged Skill"
        },
        {
          id = 10,
          type = "text",
          icon = "ui/icons/melee_defense.png",
          text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" +
            this.Math.round((this.Const.Ajfa.LoneWolfMeleeDefenseMult - 1) * 100) + "%[/color] Melee Defense"
        },
        {
          id = 10,
          type = "text",
          icon = "ui/icons/ranged_defense.png",
          text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" +
            this.Math.round((this.Const.Ajfa.LoneWolRangedDefenseMult - 1) * 100) + "%[/color] Ranged Defense"
        },
        {
          id = 10,
          type = "text",
          icon = "ui/icons/bravery.png",
          text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" +
            this.Math.round((this.Const.Ajfa.LoneWolfBraveryMult - 1) * 100) + "%[/color] Resolve"
        }
      ];
    };
  }, false, false);
};

local nerfBattleStandard = function() {
  gt.Const.Ajfa.BattleStandardResolveMult <- 0.12;
  gt.Const.Ajfa.BattleStandardResolveMultPerTileDistance <- -0.02;
  gt.Const.Ajfa.BattleStandardMaxRange <- 5;

  ::mods_hookClass("items/tools/player_banner", function(c) {
    c = ::mods_getClassForOverride(c, "player_banner");
    c.getTooltip = function() {
      local result = this.weapon.getTooltip();
      result.push({
        id = 10,
        type = "text",
        icon = "ui/icons/special.png",
        text = "Allies at a range of " + this.Const.Ajfa.BattleStandardMaxRange +
          " tiles or less receive [color=" + this.Const.UI.Color.PositiveValue + "]" +
          this.Math.round((gt.Const.Ajfa.BattleStandardResolveMult + gt.Const.Ajfa.BattleStandardResolveMultPerTileDistance) * 100) +
          "%[/color] of the Resolve of the character holding this standard as a bonus," +
          " up to a maximum of the standard bearer\'s Resolve." +
          "With each tile distance from the standard bearer above 1," +
          " the bonus is reduced by [color=" + this.Const.UI.Color.NegativeValue + "]" +
          this.Math.round(-gt.Const.Ajfa.BattleStandardResolveMultPerTileDistance * 100) + "%[/color]." +
          "The standard must be in the vision radius to receive the bonus."
      });
      return result;
    };
  }, false, false);

  ::mods_hookClass("skills/effects/battle_standard_effect", function(c) {
    c = ::mods_getClassForOverride(c, "battle_standard_effect");
    c.getBonus = function(_properties) {
      local actor = this.getContainer().getActor();
      local maxDistance = this.Math.min(this.Const.Ajfa.BattleStandardMaxRange, actor.getCurrentProperties().getVision());

      if (!actor.isPlacedOnMap() || ("State" in this.Tactical) && this.Tactical.State.isBattleEnded()) {
        return 0;
      }

      local myTile = actor.getTile();
      local allies = this.Tactical.Entities.getInstancesOfFaction(actor.getFaction());
      local bestBraveryBonus = 0;

      foreach(ally in allies) {
        if (ally.getID() == actor.getID() || !ally.isPlacedOnMap()) {
          continue;
        }


        local dist = ally.getTile().getDistanceTo(myTile);
        if (dist > maxDistance) {
          continue;
        }

        if (_properties.Bravery * _properties.BraveryMult >= ally.getBravery()) {
          continue;
        }

        if (ally.getItems().getItemAtSlot(this.Const.ItemSlot.Mainhand) != null &&
          ally.getItems().getItemAtSlot(this.Const.ItemSlot.Mainhand).getID() == "weapon.player_banner") {
          local mult = this.Const.Ajfa.BattleStandardResolveMult +
            dist * this.Const.Ajfa.BattleStandardResolveMultPerTileDistance;
          local standardBearerBravery = ally.getBravery();
          local braveryBonus = this.Math.min(standardBearerBravery * mult,
            standardBearerBravery - _properties.Bravery * _properties.BraveryMult);
          bestBraveryBonus = (braveryBonus > bestBraveryBonus ? braveryBonus : bestBraveryBonus);
        }
      }

      return bestBraveryBonus;
    };
  }, false, false);
};

local buffReachAdvantage = function() {
  gt.Const.Ajfa.ReachAdvantageMeleeDefenseBonusPerStack <- 6;
    gt.Const.Strings.PerkDescription.ReachAdvantage =
      "Learn to use the superior reach of large weapons to keep the enemy from getting close enough to land a good hit." +
      "\n\nEach hit with a two-handed melee weapon adds a stack of Reach Advantage" +
      " that increases your Melee Defense by [color=" + this.Const.UI.Color.PositiveValue + "]+" +
      gt.Const.Ajfa.ReachAdvantageMeleeDefenseBonusPerStack + "[/color]," +
      " up to a maximum of 5 stacks, until this character\'s next turn." +
      " A single attack hitting multiple targets can add several stacks at once." +
      "\n\nIf you put away your weapon, you lose all stacks.";

  local perkConsts = ::libreuse.findPerkConsts("perk.reach_advantage");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.ReachAdvantage;

  ::mods_hookClass("skills/perks/perk_reach_advantage", function(c) {
    c = ::mods_getClassForOverride(c, "perk_reach_advantage");
    c.getDescription = function() {
      return "This character is using the superior reach of their melee weapon to keep opponents at bay," +
        " increasing Melee Defense by [color=" + this.Const.UI.Color.PositiveValue + "]+" +
        this.m.Stacks * this.Const.Ajfa.ReachAdvantageMeleeDefenseBonusPerStack +
        "[/color] until their next turn.";
    };

    c.onUpdate = function(_properties) {
      this.m.IsHidden = this.m.Stacks == 0;
      local weapon = this.getContainer().getActor().getItems().getItemAtSlot(this.Const.ItemSlot.Mainhand);

      if (weapon != null && weapon.isItemType(this.Const.Items.ItemType.MeleeWeapon)
        && weapon.isItemType(this.Const.Items.ItemType.TwoHanded)) {
        _properties.MeleeDefense +=
          this.m.Stacks * this.Const.Ajfa.ReachAdvantageMeleeDefenseBonusPerStack;
      }
      else {
        this.m.Stacks = 0;
      }
    }
  });
}

local nerfDefense = function() {
  gt.Const.Ajfa.DefenseArr <- [
    0,
    7,
    13,
    18,
    22,
    26,
    30,
    34,
    38,
    41,
    44,
    47,
    49.5,
    52,
    54.5,
    57,
    59,
    61
  ];
  gt.Const.Ajfa.DefenseStep <- 5.0;

  ::mods_hookClass("entity/tactical/actor", function (c) {
    c = ::mods_getClassForOverride(c, "actor");
    c.getDefense = function(_attackingEntity, _skill, _properties) {
      local malus = 0;
      local d = 0;

      if (!this.m.CurrentProperties.IsImmuneToSurrounding)
      {
          malus = _attackingEntity != null ? this.Math.max(0, _attackingEntity.getCurrentProperties().SurroundedBonus - this.getCurrentProperties().SurroundedDefense) * this.getSurroundedCount() : this.Math.max(0, 5 - this.getCurrentProperties().SurroundedDefense) * this.getSurroundedCount();
      }

      if (_skill.isRanged())
      {
          d = _properties.getRangedDefense();
      }
      else
      {
          d = _properties.getMeleeDefense();
      }

      if (d > this.Const.Ajfa.DefenseArr[this.Const.Ajfa.DefenseArr.len() - 1]) {
        local slope = (this.Const.Ajfa.DefenseArr[this.Const.Ajfa.DefenseArr.len() - 1] -
          this.Const.Ajfa.DefenseArr[this.Const.Ajfa.DefenseArr.len() - 2]) / this.Const.Ajfa.DefenseStep;
        d = this.Const.Ajfa.DefenseArr[this.Const.Ajfa.DefenseArr.len() - 1] +
          slope * (d - this.Const.Ajfa.DefenseArr[this.Const.Ajfa.DefenseArr.len() - 1]);
      } else if (d >= 0) {
        d = ::libreuse.equidistantPiecewiseLinear(this.Const.Ajfa.DefenseArr, d / this.Const.Ajfa.DefenseStep);
      }

      if (!_skill.isRanged())
      {
          d = d - malus;
      }

      return d;
    };
  }, false, false);
};

local buffShieldwall = function() {
  gt.Const.Ajfa.ShieldwallNeighborDefenseBonus <- 7;

  ::mods_hookClass("skills/effects/shieldwall_effect", function(c) {
    c = ::mods_getClassForOverride(c, "shieldwall_effect");
    c.getBonus = function() {
        local actor = this.getContainer().getActor();

        if (!actor.isPlacedOnMap())
        {
            return 0;
        }

        local myTile = actor.getTile();
        local num = 0;

        for( local i = 0; i != 6; i = ++i )
        {
            if (!myTile.hasNextTile(i))
            {
            }
            else
            {
                local tile = myTile.getNextTile(i);

                if (!tile.IsEmpty && tile.IsOccupiedByActor && this.Math.abs(myTile.Level - tile.Level) <= 1)
                {
                    local entity = tile.getEntity();

                    if (actor.getFaction() == entity.getFaction() && entity.getSkills().hasSkill("effects.shieldwall"))
                    {
                        num = ++num;
                    }
                }
            }
        }

        return this.Math.min(this.Const.Combat.ShieldWallMaxAllies, num) * this.Const.Ajfa.ShieldwallNeighborDefenseBonus;
    };
  }, false, false);

  ::mods_hookClass("skills/actives/shieldwall", function(c) {
    c = ::mods_getClassForOverride(c, "shieldwall");
    c.getTooltip = function() {
        local p = this.getContainer().getActor().getCurrentProperties();
        local item = this.getContainer().getActor().getItems().getItemAtSlot(this.Const.ItemSlot.Offhand);
        local mult = 1.0;

        if (this.getContainer().getActor().getCurrentProperties().IsSpecializedInShields)
        {
            mult = mult * 1.25;
        }

        return [
            {
                id = 1,
                type = "title",
                text = this.getName()
            },
            {
                id = 2,
                type = "description",
                text = this.getDescription()
            },
            {
                id = 3,
                type = "text",
                text = this.getCostString()
            },
            {
                id = 4,
                type = "text",
                icon = "ui/icons/melee_defense.png",
                text = "Grants [color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Math.floor(item.getMeleeDefense() * mult) + "[/color] Melee Defense for one turn"
            },
            {
                id = 5,
                type = "text",
                icon = "ui/icons/ranged_defense.png",
                text = "Grants [color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Math.floor(item.getRangedDefense() * mult) + "[/color] Ranged Defense for one turn"
            },
            {
                id = 6,
                type = "text",
                icon = "ui/icons/melee_defense.png",
                text = "Grants an additional [color=" + this.Const.UI.Color.PositiveValue + "]+" + this.Const.Ajfa.ShieldwallNeighborDefenseBonus + "[/color] Defense against all attacks for each ally adjacent also using Shieldwall"
            }
        ];
    };
  }, false, false);
};

local buffShields = function() {
  gt.Const.Ajfa.MeleeDefenseAdd <- 1;
  gt.Const.Ajfa.RangedDefenseAdd <- 1;

  ::mods_hookClass("items/shields/shield", function(c) {
    c.createAjfaOriginalShield <- c.create;
    c.create = function() {
      this.createAjfaOriginalShield();
      this.m.MeleeDefense += this.Const.Ajfa.MeleeDefenseAdd;
      this.m.RangedDefense += this.Const.Ajfa.RangedDefenseAdd;
    };
  }, true, true);

  ::mods_hookClass("items/shields/named/named_shield", function(c) {
    c.createAjfaOriginalNamedShield <- c.create;
    c.create = function() {
      this.createAjfaOriginalNamedShield();
      this.m.MeleeDefense += this.Const.Ajfa.MeleeDefenseAdd;
      this.m.RangedDefense += this.Const.Ajfa.RangedDefenseAdd;
    };
  }, true, true);
};

local nerf2HWeapon = function(o) {
  if (!o.isItemType(this.Const.Items.ItemType.MeleeWeapon) ||
    !o.isItemType(this.Const.Items.ItemType.TwoHanded)) {
    return;
  }
  o.m.RegularDamage -= this.Math.round(this.Const.Ajfa.DamgeMinAvgMult * (o.m.RegularDamage + o.m.RegularDamageMax) / 2);
};

local nerf2HWeapons = function() {
  gt.Const.Ajfa.DamgeMinAvgMult <- 0.05;

  ::mods_hookClass("items/weapons/weapon", function(c) {
    c.createAjfaOriginalWeapon <- c.create;
    c.create = function() {
      this.createAjfaOriginalWeapon();
      nerf2HWeapon(this);
    };
  }, true, true);

  ::mods_hookClass("items/weapons/named/named_weapon", function(c) {
    c.createAjfaOriginalNamedWeapon <- c.create;
    c.create = function() {
      this.createAjfaOriginalNamedWeapon();
      nerf2HWeapon(this);
    };
  }, true, true);
};

local rebalanceEnemiesStrength = function() {
  gt.Const.World.Spawn.Troops.SkeletonMedium.Strength -= 1;
  gt.Const.World.Spawn.Troops.SkeletonMedium.Cost -= 1;
  gt.Const.World.Spawn.Troops.SkeletonMediumPolearm.Strength -= 1;
  gt.Const.World.Spawn.Troops.SkeletonMediumPolearm.Cost -= 1;
  gt.Const.World.Spawn.Troops.SkeletonHeavy.Strength -= 2;
  gt.Const.World.Spawn.Troops.SkeletonHeavy.Cost -= 2;
  gt.Const.World.Spawn.Troops.SkeletonHeavyPolearm.Strength -= 2;
  gt.Const.World.Spawn.Troops.SkeletonHeavyPolearm.Cost -= 2;
  gt.Const.World.Spawn.Troops.SkeletonHeavyBodyguard.Strength -= 2;
  gt.Const.World.Spawn.Troops.SkeletonHeavyBodyguard.Cost -= 2;
  gt.Const.World.Spawn.Troops.Vampire.Strength += 3;
  gt.Const.World.Spawn.Troops.Vampire.Cost += 3;
  gt.Const.World.Spawn.Troops.VampireLOW.Strength += 3;
  gt.Const.World.Spawn.Troops.VampireLOW.Cost += 3;
  gt.Const.World.Spawn.Troops.DirewolfHIGH.Strength += 1;
  gt.Const.World.Spawn.Troops.DirewolfHIGH.Cost += 1;
  gt.Const.World.Spawn.Troops.DirewolfBodyguard.Strength += 1;
  gt.Const.World.Spawn.Troops.DirewolfBodyguard.Cost += 1;
  gt.Const.World.Spawn.Troops.Hyena.Strength += 1;
  gt.Const.World.Spawn.Troops.Hyena.Cost += 1;
  gt.Const.World.Spawn.Troops.HyenaHIGH.Strength += 2;
  gt.Const.World.Spawn.Troops.HyenaHIGH.Cost += 2;
  gt.Const.World.Spawn.Troops.SandGolem.Strength += 1;
  gt.Const.World.Spawn.Troops.SandGolem.Cost += 1;
  gt.Const.World.Spawn.Troops.SandGolemMEDIUM.Strength += 2;
  gt.Const.World.Spawn.Troops.SandGolemMEDIUM.Cost += 2;
  gt.Const.World.Spawn.Troops.SandGolemHIGH.Strength += 3;
  gt.Const.World.Spawn.Troops.SandGolemHIGH.Cost += 3;
  gt.Const.World.Spawn.Troops.Schrat.Strength += 2;
  gt.Const.World.Spawn.Troops.Schrat.Cost += 2;
  gt.Const.World.Spawn.Troops.Serpent.Strength += 2;
  gt.Const.World.Spawn.Troops.Serpent.Cost += 2;
  gt.Const.World.Spawn.Troops.BarbarianUnhold.Strength += 2;
  gt.Const.World.Spawn.Troops.BarbarianUnhold.Cost += 2;
  gt.Const.World.Spawn.Troops.BarbarianUnholdFrost.Strength += 3;
  gt.Const.World.Spawn.Troops.BarbarianUnholdFrost.Cost += 3;
  gt.Const.World.Spawn.Troops.Unhold.Strength += 2;
  gt.Const.World.Spawn.Troops.Unhold.Cost += 2;
  gt.Const.World.Spawn.Troops.UnholdFrost.Strength += 3;
  gt.Const.World.Spawn.Troops.UnholdFrost.Cost += 3;
  gt.Const.World.Spawn.Troops.UnholdBog.Strength += 2;
  gt.Const.World.Spawn.Troops.UnholdBog.Cost += 2;
  gt.Const.World.Spawn.Troops.GoblinSkirmisher.Strength += 1;
  gt.Const.World.Spawn.Troops.GoblinSkirmisher.Cost += 1;
  gt.Const.World.Spawn.Troops.GoblinAmbusher.Strength += 1;
  gt.Const.World.Spawn.Troops.GoblinAmbusher.Cost += 1;
  gt.Const.World.Spawn.Troops.GoblinOverseer.Strength += 1;
  gt.Const.World.Spawn.Troops.GoblinOverseer.Cost += 1;
  gt.Const.World.Spawn.Troops.BanditRaider.Strength += 1;
  gt.Const.World.Spawn.Troops.BanditRaider.Cost += 1;
  gt.Const.World.Spawn.Troops.BanditRaiderLOW.Strength += 1;
  gt.Const.World.Spawn.Troops.BanditRaiderLOW.Cost += 1;
  gt.Const.World.Spawn.Troops.BanditRaiderWolf.Strength += 1;
  gt.Const.World.Spawn.Troops.BanditRaiderWolf.Cost += 1;
  gt.Const.World.Spawn.Troops.BanditLeader.Strength += 2;
  gt.Const.World.Spawn.Troops.BanditLeader.Cost += 2;
  gt.Const.World.Spawn.Troops.NomadLeader.Strength += 2;
  gt.Const.World.Spawn.Troops.NomadLeader.Cost += 2;
  gt.Const.World.Spawn.Troops.DesertDevil.Strength += 1;
  gt.Const.World.Spawn.Troops.DesertDevil.Cost += 1;
  gt.Const.World.Spawn.Troops.Executioner.Strength += 1;
  gt.Const.World.Spawn.Troops.Executioner.Cost += 1;
  gt.Const.World.Spawn.Troops.DesertStalker.Strength += 3;
  gt.Const.World.Spawn.Troops.DesertStalker.Cost += 3;
  gt.Const.World.Spawn.Troops.BarbarianThrall.Strength += 1;
  gt.Const.World.Spawn.Troops.BarbarianThrall.Cost += 1;
  gt.Const.World.Spawn.Troops.BarbarianMarauder.Strength += 3;
  gt.Const.World.Spawn.Troops.BarbarianMarauder.Cost += 3;
  gt.Const.World.Spawn.Troops.BarbarianChampion.Strength += 3;
  gt.Const.World.Spawn.Troops.BarbarianChampion.Cost += 3;
  gt.Const.World.Spawn.Troops.BarbarianChosen.Cost += 3;
  gt.Const.World.Spawn.Troops.Conscript.Strength -= 1;
  gt.Const.World.Spawn.Troops.Conscript.Cost -= 1;
  gt.Const.World.Spawn.Troops.ConscriptPolearm.Strength -= 1;
  gt.Const.World.Spawn.Troops.ConscriptPolearm.Cost -= 1;
  gt.Const.World.Spawn.Troops.Officer.Strength += 1;
  gt.Const.World.Spawn.Troops.Officer.Cost += 1;
  gt.Const.World.Spawn.Troops.Billman.Strength += 1;
  gt.Const.World.Spawn.Troops.Billman.Cost += 1;
  gt.Const.World.Spawn.Troops.Arbalester.Strength += 1;
  gt.Const.World.Spawn.Troops.Arbalester.Cost += 1;
  gt.Const.World.Spawn.Troops.Sergeant.Strength -= 1;
  gt.Const.World.Spawn.Troops.Sergeant.Cost -= 1;
  gt.Const.World.Spawn.Troops.Knight.Strength += 1;
  gt.Const.World.Spawn.Troops.Knight.Cost += 1;
  gt.Const.World.Spawn.Troops.Mercenary.Strength += 2;
  gt.Const.World.Spawn.Troops.Mercenary.Cost += 2;
  gt.Const.World.Spawn.Troops.MercenaryLOW.Strength += 1;
  gt.Const.World.Spawn.Troops.MercenaryLOW.Cost += 1;
  gt.Const.World.Spawn.Troops.MercenaryRanged.Strength += 2;
  gt.Const.World.Spawn.Troops.MercenaryRanged.Cost += 2;
  gt.Const.World.Spawn.Troops.Swordmaster.Strength += -1;
  gt.Const.World.Spawn.Troops.Swordmaster.Cost += -1;
  gt.Const.World.Spawn.Troops.HedgeKnight.Strength += 1;
  gt.Const.World.Spawn.Troops.HedgeKnight.Cost += 1;
  gt.Const.World.Spawn.Troops.MasterArcher.Strength += 2;
  gt.Const.World.Spawn.Troops.MasterArcher.Cost += 2;
  gt.Const.World.Spawn.Troops.Cultist.Strength += 1;
  gt.Const.World.Spawn.Troops.Cultist.Cost += 1;
  gt.Const.World.Spawn.Troops.ZombieKnight.Strength -= 1;
  gt.Const.World.Spawn.Troops.ZombieKnight.Cost -= 1;
  gt.Const.World.Spawn.Troops.ZombieKnightBodyguard.Strength -= 1;
  gt.Const.World.Spawn.Troops.ZombieKnightBodyguard.Cost -= 1;
  gt.Const.World.Spawn.Troops.ZombieBetrayer.Strength -= 1;
  gt.Const.World.Spawn.Troops.ZombieBetrayer.Cost -= 1;
  gt.Const.World.Spawn.Troops.ZombieBoss.Strength -= 1;
  gt.Const.World.Spawn.Troops.ZombieBoss.Cost -= 1;
};

local rebalancePlayerStrength = function() {
  gt.Const.Ajfa.PlayerStrengthPerLevel <- 2.1;
  ::mods_hookClass("entity/world/player_party", function(c) {
    c = ::mods_getClassForOverride(c, "player_party");
    c.updateStrength = function() {
      this.m.Strength = 0.0;
      local roster = this.World.getPlayerRoster().getAll();

      if (roster.len() > this.World.Assets.getBrothersScaleMax()) {
        roster.sort(this.onLevelCompare);
      }

      if (roster.len() < this.World.Assets.getBrothersScaleMin()) {
        this.m.Strength += 10.0 * (this.World.Assets.getBrothersScaleMin() - roster.len());
      }

      foreach(i, bro in roster) {
        if (i >= this.World.Assets.getBrothersScaleMax()) {
          break;
        }

        this.m.Strength += 10.0 + (bro.getLevel() - 1) * this.Const.Ajfa.PlayerStrengthPerLevel;
      }
    }
  }, false, false);
};

::mods_queue("and_justice_for_all", "mod_hooks(>=20),libreuse(>=0.3)", function() {
  setupRootTableStructure();

  buffAttributesLeveling();

  buffFastAdaptation();
  buffCripplingStrikes();
  nerfColossus();
  buffNineLives();
  buffBagsAndBelts();
  buffAdrenaline();
  buffCoupDeGrace();
  buffBullseye();
  //nerfGifted();
  //nerfFortifiedMind();
  buffAnticipation();
  buffTaunt();
  nerfPolearmMastery();
  nerfThrowingMastery();
  buffThrowingWithoutMastery();
  buffReachAdvantage();
  //nerfLoneWolf();
  buffFootwork();
  buffHeadHunter();
  nerfNimble();
  nerfBattleForged();

  nerfBattleStandard();

  nerfDefense();
  buffShieldwall();
  buffShields();
  nerf2HWeapons();

  rebalanceEnemiesStrength();
  rebalancePlayerStrength();
});
