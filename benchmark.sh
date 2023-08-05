cd /code/detach-deps/jube/
jube run jube-ubuntu-fiber-mini.xml
jube analyse bench_run -id 1
jube result bench_run -id 1
python3 gen_diag.py 000001/result/time_csv.dat
