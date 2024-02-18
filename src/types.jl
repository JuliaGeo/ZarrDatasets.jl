
struct ZarrVariable{T,N,TZA,TZG} <: CDM.AbstractVariable{T,N} where TZA  <: AbstractArray{T,N}
    zarray::TZA
    parentdataset::TZG
end

struct ZarrDataset{TZ,TP,Tmaskingvalue} <: CDM.AbstractDataset
    zgroup::TZ
    parentdataset::TP
    dimensions::OrderedDict{Symbol,Int}
    iswritable::Bool
    maskingvalue::Tmaskingvalue
end
