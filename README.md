# repec-groupquery
This Julia script downloads and formats lists of RePEc article entries for groups of authors. This script was written to help populate research pages of the Macroeconomics Group at the University of Kent. The outputs produced are imperfect and do typically require some additional editing before publication.

# User inputs
1. RePEc department series code to be updated within repec_dl.jl (line 22). For example, the University of Kent Economics Department series code is deukcuk, see https://edirc.repec.org/data/deukcuk.html.
2. List of author names in authorlist.csv. Only the surnames are used currently. Include all possible spellings (with/without accents, all caps and so on).
3. Starting year within repec_dl.jl (line 15).

# Outputs (saved to file)
1. A list of working papers, wp.html
2. A list of journal articles, ja.html
