module load clang/15-fiber CMake Ninja Python JUBE Tk
cd code/detach-deps/jube/
jube run jube-claix-fiber.xml --tag 14
jube analyse bench_run
jube result bench_run > result-14.txt
python3 gen_diag.py result-14.txt -14
jube run jube-claix-fiber.xml --tag 15
jube analyse bench_run
jube result bench_run > result-15.txt
python3 gen_diag.py result-15.txt -15
