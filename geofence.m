%%
clc;
clear;
close all;

%%
% data = textread('D:\NCHU_Work\Verilog\CIC_2021\geofence\grad.data', 'delimiter','object');
file = 'D:\NCHU_Work\Verilog\CIC_2021\geofence\grad.data';
fid = fopen(file);
count1 = 1;
data2(:,1:3) = 0;

while true
    tline = fgetl(fid);
    if(tline == -1)
       break; 
    end
    data1 = strsplit(tline);
    if(count1 == 1 | mod(count1-1,7) == 0)
        data1(1:2) = '';
    end
    
    data3 = str2double(data1);
    data4=find(~isnan(data3));
    data3=data3(data4);
    data2(count1,:) = data3;
    count1 = count1+1;
end

fclose(fid);

%%
%%%test1
% data_x(1:6) = [103,755,103,982,298,710];
% data_y(1:6) = [340,510,50,280,560,50];
% data_r(1:6) = [118,567,294,763,252,599];
%%%test2
% data_x(1:6) = [298,103,103,710,755,982];
% data_y(1:6) = [560,50,340,50,510,280];
% data_r(1:6) = [178,680,397,830,574,879];
% %%test6
% data_x(1:6) = [755,103,710,982,298,103];
% data_y(1:6) = [510,340,50,280,560,50];
% data_r(1:6) = [580,285,1021,898,296,743];

patten_number = 9;


data_x(1:6) = data2((patten_number-1)*7+2:(patten_number-1)*7+7,1);
data_y(1:6) = data2((patten_number-1)*7+2:(patten_number-1)*7+7,2);
data_r(1:6) = data2((patten_number-1)*7+2:(patten_number-1)*7+7,3);

x0 = data_x(1);
y0 = data_y(1);

temp_x = 0;
temp_y = 0;
temp_r = 0;

count = 1;
fit = 0;


while true
    x1 = data_x(2);
    x2 = data_x(3);
    y1 = data_y(2);
    y2 = data_y(3);
    data_ans = (x1-x0) * (y2-y0) - (x2-x0) * (y1-y0);
    
    
    if(data_ans >= 0)
        temp_x = data_x(2);
        temp_y = data_y(2);
        temp_r = data_r(2);
        data_x(2) = data_x(3);
        data_y(2) = data_y(3);
        data_r(2) = data_r(3);
        data_x(3) = temp_x;
        data_y(3) = temp_y;
        data_r(3) = temp_r;
        fit = 1;
    end
    
    
    if(count == 4 && fit == 0)
        for j = 1:2
            temp_x = data_x(2);
            temp_y = data_y(2);
            temp_r = data_r(2);
            for i = 2:5
                data_x(i) = data_x(i+1);
                data_y(i) = data_y(i+1);
                data_r(i) = data_r(i+1);
            end
            data_x(6) = temp_x;
            data_y(6) = temp_y;
            data_r(6) = temp_r;
        end
        break;
    elseif(count == 4 && fit == 1)
         for j = 1:2
            temp_x = data_x(2);
            temp_y = data_y(2);
            temp_r = data_r(2);
            for i = 2:5
                data_x(i) = data_x(i+1);
                data_y(i) = data_y(i+1);
                data_r(i) = data_r(i+1);
            end
            data_x(6) = temp_x;
            data_y(6) = temp_y;
            data_r(6) = temp_r;
        end
        count = 1;
        fit = 0;
    else
        temp_x = data_x(2);
        temp_y = data_y(2);
        temp_r = data_r(2);
        for i = 2:5
            data_x(i) = data_x(i+1);
            data_y(i) = data_y(i+1);
            data_r(i) = data_r(i+1);
        end
        data_x(6) = temp_x;
        data_y(6) = temp_y;
        data_r(6) = temp_r;
        count = count + 1;
    end
    
end

%%  Triangle area

a = 0;
b = 0;
c = 0;
s = 0;
all = 0;
x_y = 0;
y_x = 0;

for i = 1:6
   a =  data_r(1);
   b = data_r(2);
   
    c = sqrt(((data_x(2)-data_x(1))^2) + ((data_y(2)-data_y(1))^2));
%     c =fix(c);
   
   s = (a + b + c) / 2;
%    fix(s)
    temp = sqrt(s * abs(s-a) * abs(s-b) * abs(s-c));
   all = all + temp;
    [i,fix(temp),fix(all)]
    
   temp_x = data_x(1);
   temp_y = data_y(1);
   temp_r = data_r(1);
   for j = 1:5
       data_x(j) = data_x(j+1);
       data_y(j) = data_y(j+1);
       data_r(j) = data_r(j+1);
   end
   data_x(6) = temp_x;
   data_y(6) = temp_y;
   data_r(6) = temp_r;
end
% all = int64(all);

%% Polygon area

for i = 1:6
    x_y = x_y + data_x(1) * data_y(2);
    temp_x = data_x(1);
    temp_y = data_y(1);
    temp_r = data_r(1);
    for j = 1:5
        data_x(j) = data_x(j+1);
        data_y(j) = data_y(j+1);
        data_r(j) = data_r(j+1);
    end
    data_x(6) = temp_x;
    data_y(6) = temp_y;
    data_r(6) = temp_r;
end

for i = 1:6
    y_x = y_x + data_y(1) * data_x(2);
    temp_x = data_x(1);
    temp_y = data_y(1);
    temp_r = data_r(1);
    for j = 1:5
        data_x(j) = data_x(j+1);
        data_y(j) = data_y(j+1);
        data_r(j) = data_r(j+1);
    end
    data_x(6) = temp_x;
    data_y(6) = temp_y;
    data_r(6) = temp_r;
end

% 
% for i = 1:6
%     x_y =  data_x(1) * data_y(2);
%     y_x = data_y(1) * data_x(2);
%     temp = temp + (x_y - y_x)
%     temp_x = data_x(1);
%     temp_y = data_y(1);
%     temp_r = data_r(1);
%     for j = 1:5
%         data_x(j) = data_x(j+1);
%         data_y(j) = data_y(j+1);
%         data_r(j) = data_r(j+1);
%     end
%     data_x(6) = temp_x;
%     data_y(6) = temp_y;
%     data_r(6) = temp_r;
% end

area = abs(x_y - y_x) / 2;
% area = abs(temp) / 2;

if(all > area)
    fit_ans = 0 ;
else
    fit_ans = 1 ;
end

if(fit_ans == data2((patten_number-1)*7+1,1))
   pass = 'pass';
else
   pass = 'fall';
end
['patten : '+string(patten_number),string(pass);
    'Triangle area : '+string(all),'Polygon area : '+string(area);
    'Golde : '+string(data2((patten_number-1)*7+1,1)),'Return : '+string(fit_ans)]

