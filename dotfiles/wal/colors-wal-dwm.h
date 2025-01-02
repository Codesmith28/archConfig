static const char norm_fg[] = "#c5f5f5";
static const char norm_bg[] = "#060D13";
static const char norm_border[] = "#89abab";

static const char sel_fg[] = "#c5f5f5";
static const char sel_bg[] = "#076B89";
static const char sel_border[] = "#c5f5f5";

static const char urg_fg[] = "#c5f5f5";
static const char urg_bg[] = "#837B70";
static const char urg_border[] = "#837B70";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
