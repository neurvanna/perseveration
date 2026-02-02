function data = merge_datas(datas)
% Takes a cell of data structs and merges them into a single data struct

%% Recursive logic for merging a whole list of data structs

if length(datas) == 1 % If there is only one: return it
    data = datas{1};
elseif length(datas) == 2 % If there are only two: merge them.
    data1 = datas{1};
    data2 = datas{2};
    data = merge_two_datas(data1, data2);
else % If there are more than two: merge one of them with the merge of the rest. 
    data1 = datas{1};
    data2 = merge_datas(datas(2:end));
    data = merge_two_datas(data1, data2);
end

%% Subfunction to merge just two data structs
    function data = merge_two_datas(data1, data2)
        
        
        % Get a cell of the field names
        fnames = fieldnames(data1);
        nFields = length(fnames);
        
        % Each iteration merges one field
        data = struct;
        for field_i = 1:nFields
            field_name = fnames{field_i};
            field_data_1 = getfield(data1, field_name);
            field_data_2 = getfield(data2, field_name);
            
            if length(field_data_1) == data1.nTrials % This is a field we should parse into sessions
                new_vals = [field_data_1, field_data_2];
                data = setfield(data, field_name, new_vals);
            else % This field does not contain trial-by-trial data - just copy it
                data = setfield(data, field_name, field_data_1);
            end
            
        end
        
        data.nTrials = data1.nTrials + data2.nTrials;
    end
end