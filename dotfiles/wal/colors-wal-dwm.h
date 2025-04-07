static const char norm_fg[] = "#97abb0";
static const char norm_bg[] = "#050C1E";
static const char norm_border[] = "#69777b";

static const char sel_fg[] = "#97abb0";
static const char sel_bg[] = "#192C47";
static const char sel_border[] = "#97abb0";

static const char urg_fg[] = "#97abb0";
static const char urg_bg[] = "#102540";
static const char urg_border[] = "#102540";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
