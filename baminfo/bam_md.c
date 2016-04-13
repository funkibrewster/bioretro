#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
//#include "htslib/faidx.h"
#include "htslib/sam.h"
#include "uthash.h"

//#include "htslib/kstring.h"
//#include "kaln.h"
//#include "kprobaln.h"


#define USE_EQUAL 1
#define DROP_TAG  2
#define BIN_QUAL  4
#define UPDATE_NM 8
#define UPDATE_MD 16
#define HASH_QNM  32

//gcc -o bam_md bam_md.c -I../htslib -I../samtools ../samtools/libbam.a ../htslib/libhts.a -lz -lm -lpthread ../samtools/kprobaln.o
//gcc -o bam_md bam_md.c -I../htslib -I../samtools ../htslib/libhts.a ../samtools/libbam.a ../samtools/kprobaln.o -lz -lm -lpthread
const char bam_nt16_nt4_table[] = { 4, 0, 1, 4, 2, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4 };
//extern char *samfaipath(const char *fn_ref);

//gcc -o bam_md bam_md.c -I../htslib ../htslib/libhts.a -lz -lm -lpthread
struct chr_pos {
	int tid;
	int pos;
	int count;
	UT_hash_handle hh;
};

struct chr_pos *soft_regions = NULL;

void bam_soft_clip_pos(bam1_t *b)
{
	uint32_t *cigar = bam_get_cigar(b);

	bam1_core_t *c = &b->core;
	int i, x, y, u = 0;
	struct chr_pos *s;
	int key, j, bq_sum;
	uint8_t *bq = 0;
	//kstring_t *str;

	//str = (kstring_t*)calloc(1, sizeof(kstring_t));
	for (i = y = 0, x = c->pos; i < c->n_cigar; ++i) {
		int j, l = cigar[i]>>4, op = cigar[i]&0xf;

		if (op == BAM_CMATCH || op == BAM_CEQUAL || op == BAM_CDIFF) {
			x += l; y += l;
		} 
		else if (op == BAM_CDEL) {
			x += l;
		} 
		else if (op == BAM_CINS) {
			y += l;
		} 
		else if (op == BAM_CSOFT_CLIP) {
			key = x;
			
			HASH_FIND_INT(soft_regions,&key,s);

			if(s == NULL){
				//printf("New pos: %d\n", key);
				s = (struct chr_pos*)malloc(sizeof(struct chr_pos));
				s->tid = c->tid;
				s->pos = x;
				s->count = 1;
				
				//bq = bam_aux_get(b, "OQ");
				bq = bam_get_qual(b);
				bq_sum = 0;
				for(j= 0; j < l; j++){
					bq_sum += bq[y+j];
					//printf("%d\t%d\tLength: %d\n",j,bq[y+j],l);
				}

				//printf("avg bq: %.4f\tLength: %d\n",(float)(bq_sum/l),l);
				//Filter high coverage
				//Filter small insert
				if(l >= 10 && (float)(bq_sum/l) > 20.0){
				//if(l >= 5){
					HASH_ADD_INT(soft_regions,pos,s);
				}
			}
			else{
				s->count++;
			}

			//printf("Read Start:%d\tQual: %d\tStart: %d\tEnd: %d\tLength: %d\n", key, c->qual, x, x+l, l);



			y += l;
		} 
		else if (op == BAM_CREF_SKIP) {
			x += l;
		}
	}

	//free(str->s); free(str);
}




//int bam_fillmd(int argc, char *argv[])
int main(int argc, char *argv[])
{

	//int c, flt_flag, tid = -2, ret, len, is_bam_out, is_sam_in, is_uncompressed, max_nm, is_realn, capQ, baq_flag;
	int n, ret;

	//samfile_t *fp, *fpout = 0;
	samFile *fp;
	//faidx_t *fai;
	//char *ref = 0, mode_w[8], mode_r[8];
	bam1_t *b;
	bam_hdr_t *header;
	char *reg = 0, *outfile = 0;
	struct chr_pos *s;
	int curr_tid = 0;
	FILE *fp_out;

	// parse the command line
	while ((n = getopt(argc, argv, "r:b:q:Q:l:f:o:")) >= 0) {
		switch (n) {
			case 'r': reg = strdup(optarg); break;   // parsing a region requires a BAM header
			case 'o': outfile = strdup(optarg); break;   // parsing a region requires a BAM header

		}
	}

    fp = sam_open(argv[optind], "r");
    if (fp == 0) return 1;

    if(outfile){
    	fp_out = fopen(outfile,"w");    	
    }
    else{
    	fp_out = stdout;
    }

    header = sam_hdr_read(fp);
    if (header == NULL || header->n_targets == 0) {
        fprintf(stderr, "[bam_fillmd] input SAM does not have header. Abort!\n");
        return 1;
    }

	hts_idx_t *idx = sam_index_load(fp, argv[optind]);

	if (idx == 0) { // index is unavailable
            fprintf(stderr, "[main_samview] random alignment retrieval only works for indexed BAM or CRAM files.\n");
            return -1;
    }

	b = bam_init1();

    if(reg){
    	hts_itr_t *iter = sam_itr_querys(idx, header, reg);
    	//printf("Region: %s\n",reg);
		
        if (iter == NULL) { // region invalid or reference name not found
      		fprintf(stderr, "[main_samview] region \"%s\" could not be parsed. Continue anyway.\n", reg);
      		return -1;
        }

        while ((ret = sam_itr_next(fp, iter, b)) >= 0){

			if( b->core.flag & (BAM_FUNMAP | BAM_FSECONDARY | BAM_FQCFAIL | BAM_FDUP) ) continue;
			if(b->core.qual < 20) continue;

			if (b->core.tid >= 0) {
				bam_soft_clip_pos(b);
			}

        }

	}

	else{		  
		while ((ret = sam_read1(fp, header, b)) >= 0) {

			if( b->core.flag & (BAM_FUNMAP | BAM_FSECONDARY | BAM_FQCFAIL | BAM_FDUP) ) continue;
			if(b->core.qual < 20) continue;
			
			if(b->core.tid != curr_tid){
				for(s= soft_regions; s != NULL; s=s->hh.next){

					if(s->count > 5){
						fprintf(fp_out,"%s\t%d\t%d\n", header->target_name[s->tid], s->pos, s->count);
						//printf("%d\t%d\t%d\n", s->tid, s->pos, s->count);
					}
				}
				fflush(fp_out);
				free(soft_regions);
				soft_regions = NULL;
				curr_tid = b->core.tid;
			}
			

			if (b->core.tid >= 0 && b->core.tid <= 23) {
				bam_soft_clip_pos(b);
			}


		}
	}
	
	bam_destroy1(b);
	sam_close(fp);

	for(s= soft_regions; s != NULL; s=s->hh.next){
		//printf("Pos: %d\tReads: %d\n", s->pos, s->count);
		if(s->count > 5){
			fprintf(fp_out,"%s\t%d\t%d\n", header->target_name[s->tid], s->pos, s->count);
			//printf("%d\t%d\t%d\n", s->tid, s->pos, s->count);

		}
	}

	return 0;
}
