static const char norm_fg[] = "#93e0d0";
static const char norm_bg[] = "#071618";
static const char norm_border[] = "#669c91";

static const char sel_fg[] = "#93e0d0";
static const char sel_bg[] = "#553190";
static const char sel_border[] = "#93e0d0";

static const char urg_fg[] = "#93e0d0";
static const char urg_bg[] = "#169972";
static const char urg_border[] = "#169972";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
