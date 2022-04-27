using BSON


function to_bson(circ::Circuit, save_path::String)
    bson(save_path, Dict("circ"=>circ))
end

function to_bson(save_path::String, circ::Circuit)
    to_bson(circ, save_path)
end

function from_bson(save_path::String)
    circ = BSON.load(save_path)["circ"]
    return circ
end