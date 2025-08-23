
"""
    ZarrVariable <: CDM.AbstractVariable

    ZarrVariable(zarray, parentdataset)

A CommonDataModel.jl compatible zarr variable.

Usually generated with `CommonDataModel.defvar(::ZarrDataset, args...; kw...)`
"""
struct ZarrVariable{T,N,TZA<:AbstractArray{T,N},TZG} <: CDM.AbstractVariable{T,N}
    zarray::TZA
    parentdataset::TZG
end

# Documented in dataset.jl
struct ZarrDataset{TDS<:Union{CDM.AbstractDataset,Nothing},Tmaskingvalue,TZ} <:
       CDM.AbstractDataset
    parentdataset::TDS
    zgroup::TZ
    dimensions::OrderedDict{Symbol,Int}
    iswritable::Bool
    maskingvalue::Tmaskingvalue
end
