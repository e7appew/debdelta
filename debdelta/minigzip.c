/* minigzip.c -- simulate gzip using the zlib compression library
 * Copyright (C) 1995-2002 Jean-loup Gailly.

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

 */

/* Mennucci 2006: simplified 
   Mennucci 2008: if -DBZIP, it becomes a minibzip2
     TODO in minibzip2 mode, it does not check and report errors.
*/

/*
 * minigzip is a minimal implementation of the gzip utility. This is
 * only an example of using zlib and isn't meant to replace the
 * full-featured gzip. No attempt is made to deal with file systems
 * limiting names to 14 or 8+3 characters, etc... Error checking is
 * very limited. So use minigzip only for testing; use gzip for the
 * real thing. On MSDOS, use only on file names without extension
 * or in pipe mode.
 */

#include <stdio.h>
#ifdef BZIP
#include <bzlib.h>
#ifndef OF /* function prototypes */
#  ifdef STDC
#    define OF(args)  args
#  else
#    define OF(args)  ()
#  endif
#endif
#define uInt int
#else /* BZIP */
#include "zlib.h"
#endif /* BZIP */

#  include <string.h>
#  include <stdlib.h>
#  include <unistd.h>


#ifdef BZIP
#  define Z_SUFFIX ".bz2"
#  define SUFFIX_LEN 4
#  define ZFILE BZFILE *
#else
#  define Z_SUFFIX ".gz"
#  define SUFFIX_LEN 3
#  define ZFILE gzFile
#endif



#define BUFLEN      16384
#define MAX_NAME_LEN 1024

#ifdef MAXSEG_64K
#  define local static
   /* Needed for systems with limitation on stack size. */
#else
#  define local
#endif

char *prog;

void error            OF((const char *msg));
void gz_compress      OF((FILE   *in, ZFILE out));
void gz_uncompress    OF((ZFILE in, FILE   *out));
void file_compress    OF((char  *file, char *mode));
void file_uncompress  OF((char  *file));
int  main             OF((int argc, char *argv[]));

/* ===========================================================================
 * Display error message and exit
 */
void error(msg)
    const char *msg;
{
    fprintf(stderr, "%s: %s\n", prog, msg);
    exit(1);
}

/* ===========================================================================
 * Compress input to output then close both files.
 */

void gz_compress(FILE   *in,    ZFILE out)
{
    local char buf[BUFLEN];
    int len;
    int err;

    for (;;) {
        len = (int)fread(buf, 1, sizeof(buf), in);
        if (ferror(in)) {
            perror("fread");
            exit(1);
        }
        if (len == 0) break;
#ifdef BZIP
	BZ2_bzwrite(out, buf, len);
#else
        if (gzwrite(out, buf, (unsigned)len) != len) error(gzerror(out, &err));
#endif
    }
    fclose(in);
#ifdef BZIP
    BZ2_bzclose(out);
#else
    if (gzclose(out) != Z_OK) error("failed gzclose");
#endif
}


/* ===========================================================================
 * Uncompress input to output then close both files.
 */
void gz_uncompress(in, out)
    ZFILE in;
    FILE   *out;
{
    local char buf[BUFLEN];
    int len;
    int err;

    for (;;) {
#ifdef BZIP 
        len = BZ2_bzread(in,buf,sizeof(buf));
#else
        len = gzread(in, buf, sizeof(buf));
        if (len < 0) error (gzerror(in, &err));
#endif
        if (len == 0) break;

        if ((int)fwrite(buf, 1, (unsigned)len, out) != len) {
            error("failed fwrite");
        }
    }
    if (fclose(out)) error("failed fclose");
#ifdef BZIP
    BZ2_bzclose(in);
#else
    if (gzclose(in) != Z_OK) error("failed gzclose");
#endif
}


/* ===========================================================================
 * Compress the given file: create a corresponding .gz file and remove the
 * original.
 */
void file_compress(file, mode)
    char  *file;
    char  *mode;
{
    local char outfile[MAX_NAME_LEN];
    FILE  *in;
    ZFILE out;

    strcpy(outfile, file);
    strcat(outfile, Z_SUFFIX);

    in = fopen(file, "rb");
    if (in == NULL) {
        perror(file);
        exit(1);
    }
#ifdef BZIP
    out = BZ2_bzopen(outfile, mode);
#else
    out = gzopen(outfile, mode);
#endif
    if (out == NULL) {
        fprintf(stderr, "%s: can't gzopen %s\n", prog, outfile);
        exit(1);
    }
    gz_compress(in, out);

    unlink(file);
}


/* ===========================================================================
 * Uncompress the given file and remove the original.
 */
void file_uncompress(file)
    char  *file;
{
    local char buf[MAX_NAME_LEN];
    char *infile, *outfile;
    FILE  *out;
    ZFILE in;
    uInt len = (uInt)strlen(file);

    strcpy(buf, file);

    if (len > SUFFIX_LEN && strcmp(file+len-SUFFIX_LEN, Z_SUFFIX) == 0) {
        infile = file;
        outfile = buf;
        outfile[len-3] = '\0';
    } else {
        outfile = file;
        infile = buf;
        strcat(infile, Z_SUFFIX);
    }
#ifdef BZIP
    in = BZ2_bzopen(infile, "rb");
#else
    in = gzopen(infile, "rb");
#endif
    if (in == NULL) {
        fprintf(stderr, "%s: can't gzopen %s\n", prog, infile);
        exit(1);
    }
    out = fopen(outfile, "wb");
    if (out == NULL) {
        perror(file);
        exit(1);
    }

    gz_uncompress(in, out);

    unlink(infile);
}


/* ===========================================================================
 * Usage:  minigzip [-d] [-f] [-h] [-r] [-1 to -9] [files...]
 *   -d : decompress
 *   -f : compress with Z_FILTERED
 *   -h : compress with Z_HUFFMAN_ONLY
 *   -r : compress with Z_RLE
 *   -1 to -9 : compression level
 */

int main(argc, argv)
    int argc;
    char *argv[];
{
    int uncompr = 0;
    ZFILE file;
    char outmode[20];

    strcpy(outmode, "wb6 ");

    prog = argv[0];
    argc--, argv++;

    while (argc > 0) {
      if (strcmp(*argv, "-d") == 0)
        uncompr = 1;
#ifndef BZIP
      else if (strcmp(*argv, "-f") == 0)
        outmode[3] = 'f';
      else if (strcmp(*argv, "-h") == 0)
        outmode[3] = 'h';
      else if (strcmp(*argv, "-r") == 0)
        outmode[3] = 'R';
#endif
      else if ((*argv)[0] == '-' && (*argv)[1] >= '1' && (*argv)[1] <= '9' &&
               (*argv)[2] == 0)
        outmode[2] = (*argv)[1];
      else
        break;
      argc--, argv++;
    }
    if (argc == 0) {
        if (uncompr) {
#ifdef BZIP
            file = BZ2_bzdopen(fileno(stdin), "r");
#else
            file = gzdopen(fileno(stdin), "rb");
#endif

            if (file == NULL) error("can't gzdopen stdin");
            gz_uncompress(file, stdout);
        } else {
#ifdef BZIP
            file = BZ2_bzdopen(fileno(stdout), outmode);
#else
            file = gzdopen(fileno(stdout), outmode);
#endif
            if (file == NULL) error("can't gzdopen stdout");
            gz_compress(stdin, file);
        }
    } else {
        do {
            if (uncompr) {
                file_uncompress(*argv);
            } else {
                file_compress(*argv, outmode);
            }
        } while (argv++, --argc);
    }
    return 0;
}
