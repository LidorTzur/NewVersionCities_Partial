function GrowthVector = CalcGrowthFromNumbers(PopulationVector)
    % מחשב את אחוז הגידול של כל שנה ביחס לשנה הראשונה (שנה 1 = 1.0)
    % PopulationVector: וקטור של מספרי אוכלוסייה (למשל מ-2019 עד 2050)
    
    BasePop = PopulationVector(1);
    GrowthVector = PopulationVector / BasePop;
end