static const char norm_fg[] = "#e2e9e2";
static const char norm_bg[] = "#011219";
static const char norm_border[] = "#9ea39e";

static const char sel_fg[] = "#e2e9e2";
static const char sel_bg[] = "#6C8978";
static const char sel_border[] = "#e2e9e2";

static const char urg_fg[] = "#e2e9e2";
static const char urg_bg[] = "#52686F";
static const char urg_border[] = "#52686F";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
