# do not look for pogfiles in this directory
# exclude_paths = ["dont_include"]  

# these files/directories shall be imported, even if they're out of path or if they're 
# include_paths = ["test_simple.py", "dont_include/test_anyway/"] 

# autoindex = False # change this to true to automatically search for pogfile.py in inferior directories.

@job(desc="Build Halcyon shared library")
def Halcyon():
    print("invoking zig build")
    env.run("zig", "build")
    os.makedirs(os.path.join(orig_dir, '../../../Binaries/ThirdParty/Halcyon/'), exist_ok = True)
    exestr = "cp -r ./zig-out/lib/* " + os.path.abspath(os.path.join(orig_dir, '../../../Binaries/ThirdParty/Halcyon/'))
    print(exestr)
    env.system(exestr)

