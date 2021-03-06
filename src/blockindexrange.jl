struct BlockIndexRange{N,R<:NTuple{N,AbstractUnitRange{Int}}}
    block::Block{N,Int}
    indices::R
end

"""
    BlockIndexRange(block, startind:stopind)

represents a cartesian range inside a block.
"""
BlockIndexRange

BlockIndexRange(block::Block{N}, inds::NTuple{N,AbstractUnitRange{Int}}) where {N} =
    BlockIndexRange{N,typeof(inds)}(inds)
BlockIndexRange(block::Block{N}, inds::Vararg{AbstractUnitRange{Int},N}) where {N} =
    BlockIndexRange(block,inds)

getindex(B::Block{N}, inds::Vararg{AbstractUnitRange{Int},N}) where N = BlockIndexRange(B,inds)

eltype(R::BlockIndexRange) = eltype(typeof(R))
eltype(::Type{BlockIndexRange{N}}) where {N} = BlockIndex{N}
eltype(::Type{BlockIndexRange{N,R}}) where {N,R} = BlockIndex{N}
if VERSION < v"0.7.0-DEV.4043"
    iteratorsize(::Type{<:BlockIndexRange}) = Base.HasShape()
else
    IteratorSize(::Type{<:BlockIndexRange}) = Base.HasShape{1}()
end

first(iter::BlockIndexRange) = BlockIndex(iter.block.n, map(first, iter.indices))
last(iter::BlockIndexRange)  = BlockIndex(iter.block.n, map(last, iter.indices))


@inline function start(iter::BlockIndexRange)
    iterfirst, iterlast = first(iter), last(iter)
    if any(map(>, iterfirst.α, iterlast.α))
        return BlockIndex(iterlast.I, iterlast.α .+ 1)
    end
    iterfirst
end
@inline function next(iter::BlockIndexRange, state)
    state, BlockIndex(state.I, inc(state.α, first(iter).α, last(iter).α))
end
@inline done(iter::BlockIndexRange, state) = state.α[end] > last(iter.indices[end])

size(iter::BlockIndexRange) = map(dimlength, first(iter).α, last(iter).α)
length(iter::BlockIndexRange) = prod(size(iter))


Block(bs::BlockIndexRange) = bs.block


### Views
Block(bs::BlockSlice{<:BlockIndexRange}) = Block(bs.block)



if VERSION < v"0.7-"
    function _unblock(cum_sizes, I::Tuple{BlockIndexRange{1,R}, Vararg{Any}}) where {R}
        B = Block(first(I))
        range = cum_sizes[Int(B)]-1 + first(I).indices[1]

        BlockSlice(I[1], range)
    end
else # only 0.7- and above support broadcasting with a Range returning a Range
    function _unblock(cum_sizes, I::Tuple{BlockIndexRange{1,R}, Vararg{Any}}) where {R}
        B = Block(first(I))
        range = cum_sizes[Int(B)]-1 .+ first(I).indices[1]

        BlockSlice(I[1], range)
    end
end


to_index(::BlockIndexRange) = throw(ArgumentError("BlockIndexRange must be converted by to_indices(...)"))

@inline to_indices(A, inds, I::Tuple{BlockIndexRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{BlockIndexRange, Vararg{Any}}) =
    to_indices(A, inds, (BlockRange.(Block.(I[1].block.n), tuple.(I[1].indices))..., tail(I)...))


# In 0.7, we need to override to_indices to avoid calling linearindices
@inline to_indices(A, I::Tuple{BlockIndexRange, Vararg{Any}}) =
    to_indices(A, axes(A), I)

reindex(V, idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:BlockIndexRange}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(BlockIndexRange(Block(idxs[1].block.indices[1][Int(subidxs[1].block.block)]),
                                                            subidxs[1].block.indices),
                                            idxs[1].indices[subidxs[1].indices]),
                                    reindex(V, tail(idxs), tail(subidxs))...))


# #################
# # support for pointers
# #################
#
# function unsafe_convert(::Type{Ptr{T}},
#                         V::SubArray{T, N, BlockArray{T, N, AT}, NTuple{N, BlockSlice{Block{1,Int}}}}) where AT <: AbstractArray{T, N} where {T,N}
#     unsafe_convert(Ptr{T}, parent(V).blocks[Int.(Block.(parentindices(V)))...])
# end
