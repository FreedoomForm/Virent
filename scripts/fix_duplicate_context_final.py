#!/usr/bin/env python3
"""
Fix duplicate 'context' parameters in method signatures.
Pattern: _method(context, BuildContext context, ...) -> _method(BuildContext context, ...)
Also fix trailing commas in call sites: _method(context, ) -> _method(context)
"""
import os, re

PAGES_DIR = "/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages"

fixes = 0

for fn in sorted(os.listdir(PAGES_DIR)):
    if not fn.endswith('.dart'): continue
    fp = os.path.join(PAGES_DIR, fn)
    with open(fp) as f: c = f.read()
    orig = c
    
    # Step 1: Fix method signatures with duplicate context parameter
    # Pattern: _method(context, BuildContext context, ...) or _method(BuildContext context, ..., context, ...)
    # We need to find ALL method definitions and check their params
    
    # Find all method definitions with their full parameter list
    # Pattern: ReturnType _methodName(params) {
    def fix_method_def(m):
        full_match = m.group(0)
        return_type = m.group(1)
        method_name = m.group(2)
        params = m.group(3)
        
        # Parse params
        param_list = [p.strip() for p in params.split(',')]
        
        # Find and fix duplicate 'context'
        context_indices = []
        for i, p in enumerate(param_list):
            if p == 'context' or p == 'BuildContext context':
                context_indices.append(i)
        
        if len(context_indices) > 1:
            # Keep only the first one, make it 'BuildContext context'
            first_idx = context_indices[0]
            param_list[first_idx] = 'BuildContext context'
            # Remove other context params
            for idx in reversed(context_indices[1:]):
                del param_list[idx]
            new_params = ', '.join(param_list)
            return return_type + ' _' + method_name + '(' + new_params + ') {'
        
        return full_match
    
    c = re.sub(
        r'((?:Widget|DataRow|Future|void|String|bool|int|double|List)\s+)_(\w+)\s*\(([^)]*)\)\s*\{',
        fix_method_def,
        c
    )
    
    # Step 2: Fix trailing commas in call sites
    # Pattern: _method(context, ) -> _method(context)
    # Pattern: _method(context, , arg) -> _method(context, arg) 
    c = re.sub(r',\s*\)', ')', c)  # Remove trailing comma before )
    c = re.sub(r',\s*,', ',', c)   # Remove double commas
    
    if c != orig:
        with open(fp, 'w') as f: f.write(c)
        fixes += 1
        print("Fixed: " + fn)

print("\n" + str(fixes) + " files fixed")
