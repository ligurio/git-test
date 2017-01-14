#! /bin/sh

test_description="Test basic features"

. ./sharness.sh

# Usage: cmp_stdout actual [commit status]...
cmp_stdout() {
	local actual=$1 &&
	shift &&

	while test $# -gt 0
	do
		echo "$(git rev-parse $1)^{tree} $2" &&
		shift 2
	done >expected-stdout &&
	test_cmp expected-stdout "$actual"
}

# The test repository consists of a linear chain of numbered commits.
# Each commit contains a file "number" containing the number of the
# commit. Each commit is pointed at by a branch "c<number>".

test_expect_success 'Set up test repository' '
	git init . &&
	git config user.name "Test User" &&
	git config user.email "user@example.com" &&
	for i in $(seq 0 10)
	do
		echo $i >number &&
		git add number &&
		git commit -m "Number $i" &&
		eval "c$i=$(git rev-parse HEAD)" &&
		git branch "c$i"
	done &&
	echo "good" >good-note &&
	echo "bad" >bad-note
'

test_expect_success 'default (passing): test range' '
	git-test add "test-number --log=numbers.log --good \*" &&
	rm -f numbers.log &&
	git-test run c2..c6 >actual-stdout &&
	cmp_stdout actual-stdout c3 good c4 good c5 good c6 good &&
	printf "default %s${LF}" 3 4 5 6 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c2^{tree} &&
	git notes --ref=tests/default show $c3^{tree} >actual-c3 &&
	test_cmp good-note actual-c3 &&
	git notes --ref=tests/default show $c6^{tree} >actual-c6 &&
	test_cmp good-note actual-c6 &&
	test_must_fail git notes --ref=tests/default show $c7^{tree}
'

test_expect_success 'default (passing): do not re-test known-good commits' '
	rm -f numbers.log &&
	git-test run c3..c5 >actual-stdout &&
	cmp_stdout actual-stdout c4 known-good c5 known-good &&
	test_must_fail test -f numbers.log
'

test_expect_success 'default (passing): do not re-test known-good subrange' '
	rm -f numbers.log &&
	git-test run c1..c7 >actual-stdout &&
	cmp_stdout actual-stdout c2 good c3 known-good c4 known-good c5 known-good c6 known-good c7 good &&
	printf "default %s${LF}" 2 7 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): do not retest known-good even with --retest' '
	rm -f numbers.log &&
	git-test run --retest c0..c8 >actual-stdout &&
	cmp_stdout actual-stdout c1 good c2 known-good c3 known-good c4 known-good c5 known-good c6 known-good c7 known-good c8 good &&
	printf "default %s${LF}" 1 8 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): retest with --force' '
	rm -f numbers.log &&
	git-test run --force c5..c9 >actual-stdout &&
	cmp_stdout actual-stdout c6 good c7 good c8 good c9 good &&
	printf "default %s${LF}" 6 7 8 9 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): forget some results' '
	rm -f numbers.log &&
	git-test run --forget c4..c7 >actual-stdout &&
	cmp_stdout actual-stdout &&
	test_must_fail test -f numbers.log &&
	test_must_fail git notes --ref=tests/default show $c5^{tree} &&
	test_must_fail git notes --ref=tests/default show $c7^{tree}
'

test_expect_success 'default (passing): retest forgotten commits' '
	rm -f numbers.log &&
	git-test run c3..c8 >actual-stdout &&
	cmp_stdout actual-stdout c4 known-good c5 good c6 good c7 good c8 known-good &&
	printf "default %s${LF}" 5 6 7 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): test a single commit' '
	git-test forget-results &&
	rm -f numbers.log &&
	git-test run c5 >actual-stdout &&
	cmp_stdout actual-stdout c5 good &&
	printf "default %s${LF}" 5 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): test a few single commits' '
	rm -f numbers.log &&
	git-test run c2 c6 c5 c4 >actual-stdout &&
	cmp_stdout actual-stdout c2 good c6 good c5 known-good c4 good &&
	printf "default %s${LF}" 2 6 4 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): test a single commit and a range' '
	git-test forget-results &&
	rm -f numbers.log &&
	git-test run c9 c4..c6 >actual-stdout &&
	cmp_stdout actual-stdout c9 good c5 good c6 good &&
	printf "default %s${LF}" 9 5 6 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): commits uniqified' '
	git-test forget-results &&
	rm -f numbers.log &&
	git-test run c4..c6 c8 c5 c3..c9 >actual-stdout &&
	cmp_stdout actual-stdout c5 good c6 good c8 good c4 good c7 good c9 good &&
	printf "default %s${LF}" 5 6 8 4 7 9 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): read commits from stdin' '
	git-test forget-results &&
	rm -f numbers.log &&
	git rev-list c2..c6 | git-test run --stdin >actual-stdout &&
	cmp_stdout actual-stdout c6 good c5 good c4 good c3 good &&
	printf "default %s${LF}" 6 5 4 3 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): combine args and stdin' '
	git-test forget-results &&
	rm -f numbers.log &&
	git rev-list c2..c6 | git-test run --stdin c5 c8 >actual-stdout &&
	cmp_stdout actual-stdout c5 good c8 good c6 good c4 good c3 good &&
	# Note that rev-list was called without --reverse:
	printf "default %s${LF}" 5 8 6 4 3 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): test range' '
	git-test forget-results &&
	git-test add "test-number --log=numbers.log --bad 4 7 8 666 --good \*" &&
	rm -f numbers.log &&
	test_expect_code 1 git-test run c2..c5 >actual-stdout &&
	cmp_stdout actual-stdout c3 good c4 bad &&
	printf "default %s${LF}" 3 4 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c2^{tree} &&
	git notes --ref=tests/default show $c3^{tree} >actual-c3 &&
	test_cmp good-note actual-c3 &&
	git notes --ref=tests/default show $c4^{tree} >actual-c4 &&
	test_cmp bad-note actual-c4 &&
	test_must_fail git notes --ref=tests/default show $c5^{tree}
'

test_expect_success 'default (failing-4-7-8): do not re-test known commits' '
	rm -f numbers.log &&
	test_expect_code 1 git-test run c2..c5 >actual-stdout &&
	cmp_stdout actual-stdout c3 known-good c4 known-bad &&
	test_must_fail test -f numbers.log
'

test_expect_success 'default (failing-4-7-8): do not re-test known subrange' '
	rm -f numbers.log &&
	test_expect_code 1 git-test run c1..c6 >actual-stdout &&
	cmp_stdout actual-stdout c2 good c3 known-good c4 known-bad &&
	printf "default %s${LF}" 2 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): retest known-bad with --retest' '
	rm -f numbers.log &&
	test_expect_code 1 git-test run --retest c1..c6 >actual-stdout &&
	cmp_stdout actual-stdout c2 known-good c3 known-good c4 bad &&
	printf "default %s${LF}" 4 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): retest with --force' '
	# Test a good commit past the failing one:
	git-test run c5..c6 &&
	rm -f numbers.log &&
	test_expect_code 1 git-test run --force c2..c6 >actual-stdout &&
	cmp_stdout actual-stdout c3 good c4 bad &&
	printf "default %s${LF}" 3 4 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c5^{tree} &&
	# The notes for c6 must also have been forgotten:
	test_must_fail git notes --ref=tests/default show $c6^{tree}
'

test_expect_success 'default (failing-4-7-8): test --keep-going' '
	git-test forget-results &&
	rm -f numbers.log &&
	test_expect_code 1 git-test run --keep-going c2..c9 >actual-stdout &&
	cmp_stdout actual-stdout c3 good c4 bad c5 good c6 good c7 bad c8 bad c9 good &&
	printf "default %s${LF}" 3 4 5 6 7 8 9 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c2^{tree} &&
	git notes --ref=tests/default show $c3^{tree} >actual-c3 &&
	test_cmp good-note actual-c3 &&
	git notes --ref=tests/default show $c4^{tree} >actual-c4 &&
	test_cmp bad-note actual-c4 &&
	git notes --ref=tests/default show $c5^{tree} >actual-c5 &&
	test_cmp good-note actual-c5 &&
	git notes --ref=tests/default show $c7^{tree} >actual-c7 &&
	test_cmp bad-note actual-c7 &&
	git notes --ref=tests/default show $c9^{tree} >actual-c9 &&
	test_cmp good-note actual-c9
'

test_expect_success 'default (failing-4-7-8): retest disjoint commits with --keep-going' '
	rm -f numbers.log &&
	test_expect_code 1 git-test run --retest --keep-going c2..c9 >actual-stdout &&
	cmp_stdout actual-stdout c3 known-good c4 bad c5 known-good c6 known-good c7 bad c8 bad c9 known-good &&
	printf "default %s${LF}" 4 7 8 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): test passing HEAD' '
	git-test forget-results &&
	rm -f numbers.log &&
	git checkout c2 &&
	git symbolic-ref HEAD >expected-branch &&
	git-test run >actual-stdout &&
	cmp_stdout actual-stdout c2 good &&
	git symbolic-ref HEAD >actual-branch &&
	test_cmp expected-branch actual-branch &&
	printf "default %s${LF}" 2 >expected &&
	test_cmp expected numbers.log &&
	git notes --ref=tests/default show $c2^{tree} >actual-c2 &&
	test_cmp good-note actual-c2
'

test_expect_success 'default (failing-4-7-8): test failing HEAD' '
	git-test forget-results &&
	rm -f numbers.log &&
	git checkout c4 &&
	git symbolic-ref HEAD >expected-branch &&
	test_expect_code 1 git-test run >actual-stdout &&
	cmp_stdout actual-stdout c4 bad &&
	git symbolic-ref HEAD >actual-branch &&
	test_cmp expected-branch actual-branch &&
	printf "default %s${LF}" 4 >expected &&
	test_cmp expected numbers.log &&
	git notes --ref=tests/default show $c4^{tree} >actual-c4 &&
	test_cmp bad-note actual-c4
'

test_expect_success 'default (failing-4-7-8): test failing explicit HEAD' '
	git-test forget-results &&
	rm -f numbers.log &&
	git checkout c4 &&
	git symbolic-ref HEAD >expected-branch &&
	test_expect_code 1 git-test run HEAD >actual-stdout &&
	cmp_stdout actual-stdout c4 bad &&
	git symbolic-ref HEAD >actual-branch &&
	test_cmp expected-branch actual-branch &&
	printf "default %s${LF}" 4 >expected &&
	test_cmp expected numbers.log &&
	git notes --ref=tests/default show $c4^{tree} >actual-c4 &&
	test_cmp bad-note actual-c4
'

test_expect_success 'default (failing-4-7-8): test passing dirty working copy' '
	git-test forget-results &&
	rm -f numbers.log &&
	git checkout c4 &&
	git symbolic-ref HEAD >expected-branch &&
	echo 42 >number &&
	test_when_finished "git reset --hard HEAD" &&
	git-test run >actual-stdout &&
	echo "working-tree good" >expected-stdout &&
	test_cmp expected-stdout actual-stdout &&
	git symbolic-ref HEAD >actual-branch &&
	test_cmp expected-branch actual-branch &&
	printf "default %s${LF}" 42 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c4^{tree}
'

test_expect_success 'default (failing-4-7-8): test failing dirty working copy' '
	git-test forget-results &&
	rm -f numbers.log &&
	git checkout c2 &&
	git symbolic-ref HEAD >expected-branch &&
	echo 666 >number &&
	test_when_finished "git reset --hard HEAD" &&
	test_expect_code 1 git-test run >actual-stdout &&
	echo "working-tree bad" >expected-stdout &&
	test_cmp expected-stdout actual-stdout &&
	git symbolic-ref HEAD >actual-branch &&
	test_cmp expected-branch actual-branch &&
	printf "default %s${LF}" 666 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c2^{tree}
'

test_expect_success 'default (retcodes): test range' '
	git-test forget-results &&
	git-test add "test-number --log=numbers.log --bad 3 7 --ret=42 5 --good \*" &&
	rm -f numbers.log &&
	test_expect_code 42 git-test run c3..c6 >actual-stdout &&
	cmp_stdout actual-stdout c4 good c5 bad &&
	printf "default %s${LF}" 4 5 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (retcodes): test range again' '
	# We do not remember return codes (should we?):
	rm -f numbers.log &&
	test_expect_code 1 git-test run c3..c6 >actual-stdout &&
	cmp_stdout actual-stdout c4 known-good c5 known-bad &&
	test_must_fail test -f numbers.log
'

test_expect_success 'default (retcodes): retest range' '
	rm -f numbers.log &&
	test_expect_code 42 git-test run --retest c3..c6 >actual-stdout &&
	cmp_stdout actual-stdout c4 known-good c5 bad &&
	printf "default %s${LF}" 5 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (retcodes): force test range' '
	rm -f numbers.log &&
	test_expect_code 42 git-test run --force c3..c6 >actual-stdout &&
	cmp_stdout actual-stdout c4 good c5 bad &&
	printf "default %s${LF}" 4 5 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (retcodes): keep-going: retcode wins if last' '
	rm -f numbers.log &&
	test_expect_code 42 git-test run --force --keep-going c1..c6 >actual-stdout &&
	cmp_stdout actual-stdout c2 good c3 bad c4 good c5 bad c6 good &&
	printf "default %s${LF}" 2 3 4 5 6 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (retcodes): keep-going: bad wins if last' '
	rm -f numbers.log &&
	test_expect_code 1 git-test run --force --keep-going c1..c8 >actual-stdout &&
	cmp_stdout actual-stdout c2 good c3 bad c4 good c5 bad c6 good c7 bad c8 good &&
	printf "default %s${LF}" 2 3 4 5 6 7 8 >expected &&
	test_cmp expected numbers.log
'

test_done
