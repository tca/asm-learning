#include <stdio.h>
#include <stdlib.h>

enum scm_type {
  scm_type_null,
  scm_type_pair,
  scm_type_number
};

enum scm_gc_mark {
  scm_gc_marked,
  scm_gc_unmarked
};

typedef struct scm scm;

struct scm {
  int size;
  enum scm_type type_tag;
  enum scm_gc_mark gc_mark;
  void *storage;
};

void* alloc_generic(scm obj) {
  scm *ptr = malloc(sizeof(scm)+obj.size);
  *ptr = obj;
  ptr->storage = ptr+1;
  return ptr;
}

scm* nil() {
  return alloc_generic((scm){ .size = 0, .type_tag = scm_type_null });
}

scm* make_num(int n) {
  scm *num = alloc_generic((scm){ .size = sizeof(int), .type_tag = scm_type_number });
  ((int*)num->storage)[0] = n;
  return num;
}

int num_value(scm *num) {
  return (((int*)num->storage)[0]);
}

scm* cons(scm *a, scm *b) {
  scm *pair = alloc_generic((scm){ .size = sizeof(scm*)*2, .type_tag = scm_type_pair});
  ((scm**)pair->storage)[0] = a;
  ((scm**)pair->storage)[1] = b;
  return pair;
}

scm* car(scm *pair){
  return ((scm**)pair->storage)[0];
}

scm* cdr(scm *pair){
  return ((scm**)pair->storage)[1];
}


void print_tree(scm *t) {
  switch(t->type_tag) {
  case scm_type_null:
    printf("()");
    break;
  case scm_type_number:
    printf("%i",num_value(t));
    break;
  case scm_type_pair:
    printf("(");
    print_tree(car(t));
    printf(" . ");
    print_tree(cdr(t));
    printf(")");
    break;
  }
}

int main() {
  print_tree(nil());
  printf("\n");
  print_tree(cons(cons(make_num(2),nil()), nil()));
  printf("\n");
  return 1;
}
