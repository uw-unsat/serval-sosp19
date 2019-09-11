struct bpf_array {
        struct bpf_map map;
        u32 elem_size;
        u32 index_mask;
        /* 'ownership' of prog_array is claimed by the first program that
         * is going to use this map or by the first program which FD is stored
         * in the map to make sure that all callers and callees have the same
         * prog_type and JITed flag
         */
        enum bpf_prog_type owner_prog_type;
        bool owner_jited;
        union {
                char value[0] __aligned(8);
                void *ptrs[0] __aligned(8);
                void __percpu *pptrs[0] __aligned(8);
        };
};
