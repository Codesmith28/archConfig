static const char norm_fg[] = "#cad9db";
static const char norm_bg[] = "#0D0E0E";
static const char norm_border[] = "#8d9799";

static const char sel_fg[] = "#cad9db";
static const char sel_bg[] = "#3789A8";
static const char sel_border[] = "#cad9db";

static const char urg_fg[] = "#cad9db";
static const char urg_bg[] = "#4E7A91";
static const char urg_border[] = "#4E7A91";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
