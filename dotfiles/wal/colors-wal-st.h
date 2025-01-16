const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#011219", /* black   */
  [1] = "#52686F", /* red     */
  [2] = "#6C8978", /* green   */
  [3] = "#5F7582", /* yellow  */
  [4] = "#738A8C", /* blue    */
  [5] = "#93A59E", /* magenta */
  [6] = "#BAC8C2", /* cyan    */
  [7] = "#e2e9e2", /* white   */

  /* 8 bright colors */
  [8]  = "#9ea39e",  /* black   */
  [9]  = "#52686F",  /* red     */
  [10] = "#6C8978", /* green   */
  [11] = "#5F7582", /* yellow  */
  [12] = "#738A8C", /* blue    */
  [13] = "#93A59E", /* magenta */
  [14] = "#BAC8C2", /* cyan    */
  [15] = "#e2e9e2", /* white   */

  /* special colors */
  [256] = "#011219", /* background */
  [257] = "#e2e9e2", /* foreground */
  [258] = "#e2e9e2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
