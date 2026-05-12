function colors = getSectorColors(n)
    base = [
        0.72 0.27 1.00;
        0.49 0.18 0.56;
        0.93 0.69 0.13;
        0.51 0.37 0.01;
        0.29 0.89 0.69;
        0.47 0.67 0.19;
        0.85 0.33 0.10;
        0.64 0.08 0.18;
        0.30 0.75 0.93;
        0.00 0.45 0.74;
        0.00 1.00 0.74;
        0.40 0.40 0.40;
    ];
    if size(base,1) < n
        base = [base; lines(n-size(base,1))];
    end
    colors = base;
end
