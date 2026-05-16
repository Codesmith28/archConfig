static const char norm_fg[] = "#c1cbcc";
static const char norm_bg[] = "#0C0F17";
static const char norm_border[] = "#878e8e";

static const char sel_fg[] = "#c1cbcc";
static const char sel_bg[] = "#4F626D";
static const char sel_border[] = "#c1cbcc";

static const char urg_fg[] = "#c1cbcc";
static const char urg_bg[] = "#325269";
static const char urg_border[] = "#325269";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
