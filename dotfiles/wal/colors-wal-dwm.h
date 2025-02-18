static const char norm_fg[] = "#80e4f0";
static const char norm_bg[] = "#0F1D32";
static const char norm_border[] = "#599fa8";

static const char sel_fg[] = "#80e4f0";
static const char sel_bg[] = "#148D6E";
static const char sel_border[] = "#80e4f0";

static const char urg_fg[] = "#80e4f0";
static const char urg_bg[] = "#93366F";
static const char urg_border[] = "#93366F";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
