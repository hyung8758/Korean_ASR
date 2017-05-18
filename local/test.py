word_opt=1
rgc = 0
rg_rem = 0
time = []
for down in range(len(mid)):
    rgc += 1
    # First line.
    if rgc == 1:
        if re.findall('[<>]', mid[down].split('\t')[-5]) != []:
            print('0' + '\n' + "{0:.2f}".format(float(mid[down].split('\t')[-1])) + '\n')
            print('"' + mid[down].split('\t')[-5] + '"' + '\n')
        else:
            print('0' + '\n')
        print("1st, First line: down " + str(down))
    # Last line
    elif down == len(mid) and rgc - 1 == len(mid):
        print("{0:.2f}".format(float(mid[down].split('\t')[-2])) + '\n' + str(end_time) + '\n')
        print('"' + mid[down].split('\t')[-5] + '"')
        print("2nd, Last line: down " + str(down))
    # Symbols
    elif re.findall('[<>]', mid[down].split('\t')[-5]) != []:
        print("{0:.2f}".format(float(mid[down].split('\t')[-2])) + '\n' + "{0:.2f}".format(
            float(mid[down].split('\t')[-1])) + '\n')
        print('"' + mid[down].split('\t')[-5] + '"' + '\n')
        print("3rd, symbols: down " +str(down))
    # Mid lines.
    elif re.findall('[<>]', mid[down].split('\t')[-5]) == [] and rgc - 1 == down:
        str_len = len(rg_list[rg_rem]) - 2
        for ram in range(str_len):
            # Time marking
            if rg_list[rg_rem][2 + ram] == mid[rgc - 1].split('\t')[-5][0:2]:
                time.append(mid[rgc - 1].split('\t')[-2])
                time.append(mid[rgc - 1].split('\t')[-1])
                rgc += 1
        print("{0:.2f}".format(float(time[0])) + '\n' + "{0:.2f}".format(float(time[-1])) + '\n')
        print('"' + rg_list[rg_rem][word_opt] + '"' + '\n')
        rg_rem += 1
        rgc -= 1
        time = []
        print("4th, mid lines: rg_rem " + str(rg_rem))
        print("4th, mid lines: rgc " + str(rgc))
        print("4th, mid lines: down " + str(down))
    else:
        rgc -= 1
        print("5th, deduction: down " + str(down))
        print("5th, deduction: rgc " + str(rgc))
print("FINISHED")
print("rg_rem is " + str(rg_rem))