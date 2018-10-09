% This script will interpret all scans in some directory
function MSQ_interpretscans(  )


%% Configuration
%Select directory than contains all mzXML files, and config files
directory = 'data';

% Select output mode
% 1 - total intensity across scans
% 2 - mean intensity

mode = 2;


%%
currdir = cd;

cd(directory)

interpretScans( mode );
 
%Return to main directory
cd(currdir)


end

function interpretScans( mode )

    flist=dir('*_auc.mat'); % looks for local mzXML files
    

    if ~isempty(flist)     
        
        data = cell(0);
        
        for i = 1:length(flist)
            
            datafilename = strrep( flist(i).name, 'auc', 'ms' );
            load(flist(i).name);
            load(datafilename);
           
            fprintf('Loading file: %s\n\n', datafilename);
         
            regCount = size( auc{1}, 2 );

            % if first file, create header
            if i == 1
                
                headers = cell(1,regCount+1);
                
                headers{1} = 'Filename';
                for k = 1:regCount
                    headers{k+1} = sprintf('%d_%s_%d', auc{1}(k).region, auc{1}(k).name, auc{1}(k).charge );
                end
                
            end
            
            numScans = size(auc,1);
            
            allAUC = [auc{:}];
            allAUC = [allAUC(:).auc];
            
            
            temp = zeros(regCount,1);
            
            for j = 1:regCount:length(allAUC)
                
                for k = 1:regCount
                    temp(k) = temp(k) + allAUC(j+(k-1));
                end
            end
            
            data{end+1, 1} = flist(i).name;
            for k = 1:regCount
                
                switch(mode)
                    case 1
                        data{end, k+1} = temp(k);
                    case 2
                        data{end, k+1} = temp(k)/numScans;

                        
                end
            end
            

        end
        
        
        
        
        out = [ headers ;data];
        
        
        filename = 'output.xlsx';
        xlswrite( filename, out); 
    end
end
