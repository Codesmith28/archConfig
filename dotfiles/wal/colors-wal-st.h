const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#050C1E", /* black   */
  [1] = "#102540", /* red     */
  [2] = "#192C47", /* green   */
  [3] = "#273A52", /* yellow  */
  [4] = "#2D465A", /* blue    */
  [5] = "#2F5368", /* magenta */
  [6] = "#33657A", /* cyan    */
  [7] = "#97abb0", /* white   */

  /* 8 bright colors */
  [8]  = "#69777b",  /* black   */
  [9]  = "#102540",  /* red     */
  [10] = "#192C47", /* green   */
  [11] = "#273A52", /* yellow  */
  [12] = "#2D465A", /* blue    */
  [13] = "#2F5368", /* magenta */
  [14] = "#33657A", /* cyan    */
  [15] = "#97abb0", /* white   */

  /* special colors */
  [256] = "#050C1E", /* background */
  [257] = "#97abb0", /* foreground */
  [258] = "#97abb0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
