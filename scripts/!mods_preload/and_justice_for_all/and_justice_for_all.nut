::mods_registerMod("and_justice_for_all", 0.1.0, "and_justice_for_all");

local gt = this.getroottable();

if (!("ajfa" in gt)) {
  ::ajfa <- {};
}

local setupRootTableStructure = function() {
  gt.Ajfa <- {};
  gt.Const.Ajfa <- {};
};

local buffAttributesLeveling = function() {
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Hitpoints].Min += 1;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Hitpoints].Max += 1;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Fatigue].Max += 1;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Bravery].Max += 1;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.Initiative].Max += 1;
  gt.Const.AttributesLevelUp[gt.Const.Attributes.RangedDefense].Max += 1;
};

local nerfColossus = function() {
  gt.Const.Ajfa.ColossusHitpointsMult <- 1.17;
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
      this.logInfo("Ajfa perk_colossus.onUpdate called.");
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
      this.logInfo("Ajfa perk_bullseye.onUpdate called.");
      _properties.RangedAttackBlockedChanceMult *= this.m.RangedAttackBlockedChanceMult;
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.bullseye");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.Bullseye;
}

local nerfThrowingMastery = function() {
  gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance2 <- 1.217;
  gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance3 <- 1.116;
  gt.Const.Strings.PerkDescription.SpecThrowing = "Master throwing weapons to wound or kill the enemy before they even get close. " +
    "Skills build up [color=" + this.Const.UI.Color.NegativeValue + "]25%[/color] less Fatigue." +
    "\n\nDamage is increased by [color=" + this.Const.UI.Color.PositiveValue + "]" + this.Math.round((gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance2 - 1) * 100) + "%[/color] when attacking at 2 tiles of distance." +
    "\n\nDamage is increased by [color=" + this.Const.UI.Color.PositiveValue + "]" + this.Math.round((gt.Const.Ajfa.ThrowingMasteryDamageMultAtDistance3 - 1) * 100) + "%[/color] when attacking at 3 tiles of distance.",

  ::mods_hookClass("skills/perks/perk_mastery_throwing", function(c) {
    c = ::mods_getClassForOverride(c, "perk_mastery_throwing");
    c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
      this.logInfo("Ajfa perk_mastery_throwing.onAnySkillUsed called.");
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
        this.logInfo("Ajfa actor.onInit called. Adding ajfa_buff_throwing.");
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
      this.logInfo("Ajfa perk_crippling_strikes.onUpdate called.");
      _properties.ThresholdToInflictInjuryMult *= this.Const.Ajfa.CripplingStrikesThresholdToInflictInjuryMult;
    };
  }, false, false);

  local perkConsts = ::libreuse.findPerkConsts("perk.crippling_strikes");
  perkConsts.Tooltip = gt.Const.Strings.PerkDescription.CripplingStrikes;
};

local buffNineLives = function() {
  gt.Const.Ajfa.NineLivesMeleeDefenseModifier <- 15;
  gt.Const.Ajfa.NineLivesRangedDefenseModifier <- 15;
  gt.Const.Ajfa.NineLivesBraveryModifier <- 15;
  gt.Const.Ajfa.NineLivesInitiativeModifier <- 15;
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
      this.logInfo("Ajfa nine_lives_effect.onUpdate called.");
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
      this.logInfo("Ajfa coup_de_grace.onAnySkillUsed called.");
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
    this.logInfo("mods_hookNewObject for Ajfa footwork called.");
    o.m.FatigueCost += this.Const.Ajfa.FootworkFatigueCostModifier;
  });
};

local buffFastAdaptation = function() {
  gt.Const.Ajfa.FastAdaptationHitChanceBonusPerStack <- 11;

  gt.Const.Strings.PerkDescription.FastAdaption =
    "Adapt to your opponent\'s moves! Gain an additional stacking [color=" + this.Const.UI.Color.PositiveValue + "]+" +
    gt.Const.Ajfa.FastAdaptationHitChanceBonusPerStack +
    "%[/color] chance to hit with each attack that misses an opponent. Bonus is reset upon landing a hit.";

  ::mods_hookClass("skills/perks/perk_fast_adaption", function(c) {
    c = ::mods_getClassForOverride(c, "perk_fast_adaption");
    c.onAnySkillUsed = function(_skill, _targetEntity, _properties) {
      this.logInfo("Ajfa perk_fast_adaption.onAnySkillUsed called.");
      if (this.m.Stacks != 0 && _skill.isAttack()) {
        _properties.MeleeSkill += this.Const.Ajfa.FastAdaptationHitChanceBonusPerStack * this.m.Stacks;
        _properties.RangedSkill += this.Const.Ajfa.FastAdaptationHitChanceBonusPerStack * this.m.Stacks;
      }
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
      this.logInfo("Ajfa perk_head_hunter.onAnySkillUsed called.");
      this.onAnySkillUsedAjfaOriginal(_skill, _targetEntity, _properties);
      if (_skill.isAttack() && this.m.Stacks != 0) {
        this.logInfo("Increase head_hunter hit chance.");
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
      this.logInfo("Ajfa perk_nimble.getChance called.");
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
      this.logInfo("Ajfa perk_battle_forged.onBeforeDamageReceived called.");
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
    c.onAfterUpdate = onAfterUpdateNew;
  }, false, false);
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
  gt.Const.World.Spawn.Troops.Swordmaster.Strength += 1;
  gt.Const.World.Spawn.Troops.Swordmaster.Cost += 1;
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

::mods_queue("and_justice_for_all", "mod_hooks(>=20),libreuse(>=0.2)", function() {
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
  buffTaunt();
  nerfPolearmMastery();
  nerfThrowingMastery();
  buffThrowingWithoutMastery();
  buffFootwork();
  buffHeadHunter();
  nerfNimble();
  nerfBattleForged();

  rebalanceEnemiesStrength();
});
