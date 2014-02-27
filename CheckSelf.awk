{
    #deal the format, remove blank, ",", $ and change the case to capital
    for(n = 1; n <= NF; n++)
    {
        gsub(/^[[:blank:]]*/,"",$(n));
        gsub(/[[:blank:]]*$/,"",$(n));
        gsub(/\$/,"",$(BALNF));
        gsub(/,/,"",$(BALNF));
        $(n)=(match($(n),/[a-z,A-Z]/)?$(n):strtonum($(n)))
        #如果报告中所有大小写统一则, 该行可注释
        #$(n)=($(n)==""?$(n):toupper($(n)));
    }
}   
