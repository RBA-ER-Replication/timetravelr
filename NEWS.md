# 0.0.2.0
* Renamed the package from RBAtardis to timetravelr for public release.

# 0.0.1.14
* Update pseudo gertrude to support tidy=T in mgertrude_timeseries.

# 0.0.1.13
* Add two functions which can retrieve the exact publication dates for which a piece of 
data is released. get_abs_publication_dates() and get_abs_publication_dates.simple().

# 0.0.1.12

* Add support for annual national accounts data in ABS.find_files.

# 0.0.1.11

* Bug fix for change implemented in previous version. 

# 0.0.1.10
* Change to a different URL parser; the Bank appears to have downgraded the version
of the curl package to before the curl::curl_parse_url function was added.

# 0.0.1.9

* Fix bug in `load_gert_vintages`, which led some dates to be read in incorrectly. 

# 0.0.1.6

* Add support for multi-series charts (show multiple series for the same vintage).

# 0.0.1.4

* Fix bug with mask_gertrude which stopped interpolation from occurring. 

# 0.0.1.3

* Fix bug with multiple vintage selections in Vintage Viewer.

# 0.0.1.2

* Allow multiple vintage selections in Vintage Viewer.

# 0.0.1.1

* Fix bug with publication offset functionality.

# 0.0.1.0

* Fix issue with arphit rendering which creates a new window containing the graph 
every time. 

# 0.0.0.6

* Cutoff date for the interpolation feature adjusted to be exclusive; e.g.
if the vintage 2011-08-01 was being 'interpolated' from the vintage '2024-05-01',
all data observations published in the month of 2011-08 will be cut off.

# 0.0.0.5

* Fix bug which meant interpolate=TRUE argument did nothing in pseudo_gertrude_timeseries. 

* Add support for publication offsets in interpolation.

# 0.0.0.4

* Add new features to vintage viewer; allow removal of certain vintages.

# 0.0.0.3

* Add vintage-viewer: A Shiny app which allows for easy viewing of a large 
amount of vintage data; generate static and dynamic plots. 

# 0.0.0.2

* Clean up and add new features (todo: add description from git commit).

# 0.0.0.1

* Push the original version of the package!
