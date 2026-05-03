SYMBOLS = 'abcdefghilklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890,.:;?!"\'`()[]{}<>@#$%^&*=_+-|\\/абвгдеёжзиклмнопрстуфхцчшщъыьэюяАБВГДЕЈЗИКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
def find_first_letter(line: str):
    for i in range(len(line)):
        if line[i] in SYMBOLS:
            return i
    return 0
        
def delete_extra_spaces(filename: str):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    for line in lines:
        last_meaningfull_space = find_first_letter(line)
        stripped_line = line.strip()
        while stripped_line.find('  ') != -1:
            stripped_line = stripped_line.replace('  ', ' ')
        lines[lines.index(line)] = ' '*last_meaningfull_space + stripped_line
    with open(filename, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line + '\n')
    

if __name__ == '__main__':
    delete_extra_spaces('7.sql')