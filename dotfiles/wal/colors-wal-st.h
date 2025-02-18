const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0F1D32", /* black   */
  [1] = "#93366F", /* red     */
  [2] = "#148D6E", /* green   */
  [3] = "#156296", /* yellow  */
  [4] = "#4D5994", /* blue    */
  [5] = "#A85B9B", /* magenta */
  [6] = "#229FC3", /* cyan    */
  [7] = "#80e4f0", /* white   */

  /* 8 bright colors */
  [8]  = "#599fa8",  /* black   */
  [9]  = "#93366F",  /* red     */
  [10] = "#148D6E", /* green   */
  [11] = "#156296", /* yellow  */
  [12] = "#4D5994", /* blue    */
  [13] = "#A85B9B", /* magenta */
  [14] = "#229FC3", /* cyan    */
  [15] = "#80e4f0", /* white   */

  /* special colors */
  [256] = "#0F1D32", /* background */
  [257] = "#80e4f0", /* foreground */
  [258] = "#80e4f0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
