function num=excelcol(str)
% Return column number for the letter-named excel column.
%

% RP Jan/2023
str=lower(str);

num=abs(str(1)-'a')+1;

for k=2:length(str)
    num=num*26+abs(str(2)-'a')+1;
end

