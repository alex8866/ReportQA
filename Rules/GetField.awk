{
    for (n=1;n<=NF;n++)
    {
        if(index($n, SS))
        {
            match($n, /\|/);
            print substr($n, RSTART+1, length($n)-RSTART) >> "junk/WhileGet.txt"
        }
    }

}
