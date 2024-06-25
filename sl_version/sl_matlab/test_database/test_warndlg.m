%% test on dialog() and warndlg() functions
% this is to initiating a warning dialog when overwite existing corrections

aa = 2;
bb = 1;

figure(2)

set(gcf,'Position',[100 100 600 600])


looping = true;

savebut=uicontrol(gcf,'style','pushbutton','tag','save',  'unit','normalized','position',[.92 .55  0.07 0.04],...
            'string','SAVE','callback','set(gcbo,''userdata'',''save'')','userdata','not done');

while looping

    if strcmp(get(savebut,'userdata'),'save')
        
        if aa == 1
            disp('saved the data!')
            break;

        elseif aa == 2
            % disp('Warning! Overiting existing correction!');

            % uialert(gcf,'Overiting existing correction!','Warning');
            answer = questdlg('Do you want to overwrite existing corrections fo image DJI_000x.JPG?', ...
            	'Warning!','yes', 'cancel','yes');

            switch answer
                case 'yes'
                    disp('Overwrite existing corrections!');
                case 'cancel'
                    disp('Kept as original!');
            end

            looping = false;

        else
            disp('aa has to be either 1 (normal) or 2 (overwrite)')

        end


    end


    pause(0.05);
end









