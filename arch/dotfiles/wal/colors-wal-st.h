const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0C0F17", /* black   */
  [1] = "#325269", /* red     */
  [2] = "#4F626D", /* green   */
  [3] = "#A37958", /* yellow  */
  [4] = "#4D7489", /* blue    */
  [5] = "#6B919F", /* magenta */
  [6] = "#76B0C5", /* cyan    */
  [7] = "#c1cbcc", /* white   */

  /* 8 bright colors */
  [8]  = "#878e8e",  /* black   */
  [9]  = "#325269",  /* red     */
  [10] = "#4F626D", /* green   */
  [11] = "#A37958", /* yellow  */
  [12] = "#4D7489", /* blue    */
  [13] = "#6B919F", /* magenta */
  [14] = "#76B0C5", /* cyan    */
  [15] = "#c1cbcc", /* white   */

  /* special colors */
  [256] = "#0C0F17", /* background */
  [257] = "#c1cbcc", /* foreground */
  [258] = "#c1cbcc",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
