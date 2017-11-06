#-------------------------------------------------------------------------------
# Preamble
#-------------------------------------------------------------------------------

println("Loading packages.")
using Requests
using DataFrames
println("Packages loaded.")

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------

authorlist  = readtable("authorlist.csv")
startdate   = "2013" # Only include papers newer than this year.

#-------------------------------------------------------------------------------
# Body
#-------------------------------------------------------------------------------

println("Downloading data.")
webresponse = get("https://ideas.repec.org/d/deukcuk.html")
println("Data downloaded.")

datastring = readstring(webresponse)

wpstart = search(datastring,"Working papers",search(datastring,"Working papers")[2])
jastart = search(datastring,"Journal articles",search(datastring,"Journal articles")[2])
bkstart = search(datastring,"Books",jastart[1])

# Working papers
println("Processing working papers.")

wpstring = datastring[maximum(wpstart)+1:minimum(jastart)-1];
wpstring = wpstring[minimum(search(wpstring,"<LI class=\"down")):minimum(search(wpstring,string("</OL><H4>",startdate,"</H4><OL>")))-1];

for iter_year in parse(startdate):Dates.year(now())
  wpstring = replace(wpstring,string("</OL><H4>",iter_year,"</H4><OL>"),"")
end

wppointer = minimum(search(wpstring,"<LI class=\"down"))
wprecord  = wpstring[wppointer:minimum(search(wpstring,"<LI class=\"down",wppointer+1))-1];
wplastrec = 0;
wpcount   = 0;
wpkept    = 0;
wpdiscard = 0;
while wplastrec == 0
  wpcount += 1;
  wpinclude = 0
  for i in 1:size(authorlist)[1]
    if contains(wprecord,authorlist[:Surname][i])
      wpinclude = 1
    end
  end
  if wpinclude == 0
    wpstring = replace(wpstring,wprecord,"")
    wppointer = wppointer
    wplastrec = try wpstring[wppointer]; 0 catch; 1 end
    wplastrec = try wpstring[wppointer:wppointer+2] == "<LI" ? 0 : 1 end
    wprecord  = try wpstring[wppointer:minimum(search(wpstring,"<LI class=\"down",wppointer+1))-1]
    catch wpstring[wppointer:length(wpstring)]
                end
    wpdiscard += 1;
  else
    try
      wppointer = minimum(search(wpstring,"<LI class=\"down",wppointer+1))
      wprecord  = try wpstring[wppointer:minimum(search(wpstring,"<LI class=\"down",wppointer+1))-1]
                  catch wpstring[wppointer:length(wpstring)]
                  end
    catch
      wplastrec = 1
    end
    wpkept += 1
  end
  if mod(wpcount,10) == 0
    println(wpcount," working papers processed.")
    println(wpkept," kept, ",wpdiscard," discarded.")
  end
end

println("Cleaning up working papers.")

wpstring = replace(wpstring,r"HREF=\"/p","HREF=\"https://ideas.repec.org/p")
wpstring = replace(wpstring,r"<B><A","<A__PH")          # Add Placeholder
wpstring = replace(wpstring,"</A></B>","</A__PH>")      # Add Placeholder
wpstring = replace(wpstring,r"<A HREF+.+html\">","<i>") # Delete journal links
wpstring = replace(wpstring,"</A>","</i>")
wpstring = replace(wpstring,r"__PH","")                 # Remove placeholder
wpstring = replace(wpstring,r".html\"",".html\" target=\"_blank\"") # Open in new tab

wpstring = replace(wpstring,"\n\",\"\n,","")
wpstring = replace(wpstring," class=\"downgate\"","")
wpstring = replace(wpstring," class=\"downfree\"","")
wpstring = replace(wpstring,"<BR><","")
wpstring = replace(wpstring,"<<","<")
wpstring = replace(wpstring,"<UL>","")
wpstring = replace(wpstring,"</UL></div>","")
wpstring = replace(wpstring,"div class=\"publishedas\">","")
wpstring = replace(wpstring,"div class=\"otherversion\">","")
wpstring = replace(wpstring,",\"","\",")


write("wp.html",wpstring);
println("Working papers processed and saved to file.")

# Journal articles
println("Processing journal articles.")

jastring = datastring[maximum(jastart)+1:minimum(bkstart)-1];
#jastring = jastring[minimum(search(jastring,"<LI class=\"down")):minimum(search(jastring,startdate))-1];
jastring = jastring[minimum(search(jastring,"<LI class=\"down")):minimum(search(jastring,string("</OL><H4>",startdate,"</H4><OL>")))-1];

jastring = replace(jastring,r"<BR><div class=\"otherversion\"><UL>+.+</UL></div>","")

for iter_year in parse(startdate):Dates.year(now())
  jastring = replace(jastring,string("</OL><H4>",iter_year,"</H4><OL>"),"")
end

japointer = minimum(search(jastring,"<LI class=\"down"))
jarecord  = jastring[japointer:minimum(search(jastring,"<LI class=\"down",japointer+1))-1];
jalastrec = 0;
jacount   = 0;
jakept    = 0;
jadiscard = 0;
while jalastrec == 0
  jacount += 1;
  jainclude = 0
  if try jastring[japointer-30:japointer-1] == "<div class=\"otherversion\"><UL>" catch; false end;
    japointemp= minimum(search(jastring,"<LI class=\"down",japointer+1))
    jainclude = 0
    jastring  = string(jastring[1:japointer-30],jastring[japointemp:length(jastring)])

    try
      japointer = minimum(search(jastring,"<LI class=\"down",japointer-30))
      jarecord  = try jastring[japointer:minimum(search(jastring,"<LI class=\"down",japointer+1))-1]
                  catch jastring[japointer:length(jastring)]
                  end
      catch
      jalastrec = 1
    end

  else
    for i in 1:size(authorlist)[1]
      if contains(jarecord,authorlist[:Surname][i]) && contains(jarecord,"HREF=\"/a")
        jainclude = 1
      end
    end

    if jainclude == 0
      jastring = replace(jastring,jarecord,"")
      japointer = japointer
      jalastrec = try jastring[japointer]; 0 catch; 1 end
      jalastrec = try jastring[japointer:japointer+2] == "<LI" ? 0 : 1 end
      jarecord  = try jastring[japointer:minimum(search(jastring,"<LI class=\"down",japointer+1))-1]
                  catch jastring[japointer:length(jastring)]
                  end
      jadiscard += 1;
    else
      try
        japointer = minimum(search(jastring,"<LI class=\"down",japointer+1))
        jarecord  = try jastring[japointer:minimum(search(jastring,"<LI class=\"down",japointer+1))-1]
                    catch jastring[japointer:length(jastring)]
                    end
        catch
        jalastrec = 1
      end
      jakept += 1
    end
  end
  if mod(jacount,10) == 0
    println(jacount," journal articles processed.")
    println(jakept," kept, ",jadiscard," discarded.")
  end
end

println("Cleaning up journal articles.")


jastring = replace(jastring,r"HREF=\"/a","HREF=\"https://ideas.repec.org/a")
jastring = replace(jastring,r"<B><A","<A__PH")          # Add Placeholder
jastring = replace(jastring,"</A></B>","</A__PH>")      # Add Placeholder
jastring = replace(jastring,r"<A HREF+.+html\">","<i>") # Delete journal links
jastring = replace(jastring,"</A>","</i>")
jastring = replace(jastring,r"__PH","")                 # Remove placeholder
jastring = replace(jastring,r".html\"",".html\" target=\"_blank\"") # Open in new tab
jastring = replace(jastring,"\n\",\"\n,","")
jastring = replace(jastring," class=\"downgate\"","")
jastring = replace(jastring," class=\"downfree\"","")
jastring = replace(jastring,"<BR><","")
jastring = replace(jastring,"<UL>","")
jastring = replace(jastring,"</UL></div>","")
jastring = replace(jastring,",\"","\",")

write("ja.html",jastring);
println("Journal articles processed and saved to file.")
