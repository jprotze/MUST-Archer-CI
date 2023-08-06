cd code/detach-deps/jube/
jube run jube-ubuntu-fiber.xml --tag test
jube analyse bench_run 
jube result bench_run > result-test.txt
python3 gen_diag.py result-test.txt -test
