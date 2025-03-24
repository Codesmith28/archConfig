static const char norm_fg[] = "#bdbca3";
static const char norm_bg[] = "#090e0a";
static const char norm_border[] = "#848372";

static const char sel_fg[] = "#bdbca3";
static const char sel_bg[] = "#336127";
static const char sel_border[] = "#bdbca3";

static const char urg_fg[] = "#bdbca3";
static const char urg_bg[] = "#2F4C29";
static const char urg_border[] = "#2F4C29";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
