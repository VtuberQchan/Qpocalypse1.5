Recipe = Recipe or {}
Recipe.OnGiveXP = Recipe.OnGiveXP or {}
Recipe.OnGiveXP.Qpocalypse15 = Recipe.OnGiveXP.Qpocalypse15 or {}

function Recipe.OnGiveXP.Qpocalypse15.Doctor10(recipe, ingredients, result, player)
    player:getXp():AddXP(Perks.Doctor, 10);
end

function Recipe.OnGiveXP.Qpocalypse15.Doctor15(recipe, ingredients, result, player)
    player:getXp():AddXP(Perks.Doctor, 15);
end

function Recipe.OnGiveXP.Qpocalypse15.Doctor20(recipe, ingredients, result, player)
    player:getXp():AddXP(Perks.Doctor, 20);
end

function Recipe.OnGiveXP.Qpocalypse15.Doctor25(recipe, ingredients, result, player)
    player:getXp():AddXP(Perks.Doctor, 25);
end