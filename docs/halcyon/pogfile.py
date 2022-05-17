# do not look for pogfiles in this directory
# exclude_paths = ["dont_include"]  

# these files/directories shall be imported, even if they're out of path or if they're 
# include_paths = ["test_simple.py", "dont_include/test_anyway/"] 

# autoindex = False # change this to true to automatically search for pogfile.py in inferior directories.

@job(desc="Hello World job, this is the toplevel default target")
def make_release():
    env.system('make html')
    shutil.copytree('build/html', './site/')
    env.run("git", "add", '-u', cwd='./site')
    env.run("git", "commit", '-m', 'automatic build', cwd='./site')
    env.run("git", "push", '-u', 'origin', cwd='./site')
