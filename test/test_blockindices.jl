import BlockArrays: BlockSizes, BlockIndex, globalrange, nblocks, global2blockindex, blockindex2global

#=
[1,1  1,2] | [1,3  1,4  1,5]
--------------------------
[2,1  2,2] | [2,3  2,4  2,5]
[3,1  3,2] | [3,3  3,4  3,5]
----------------------------
[4,1  4,2] | [4,3  4,4  4,5]
[5,1  5,2] | [5,3  5,4  5,5]
[6,1  6,2] | [6,3  6,4  6,5]
=#

block_size = BlockSizes([1,2,3], [2, 3])

@testset "BlockSizes / BlockIndices" begin
@test nblocks(block_size) == (3,2)
@test nblocks(block_size, 1) == 3
@test nblocks(block_size, 2) == 2

@inferred globalrange(block_size, (1,1)) == (1:1, 1:2)
@inferred globalrange(block_size, (1,2)) == (1:1, 3:5)
@inferred globalrange(block_size, (2,1)) == (2:3, 1:2)
@inferred globalrange(block_size, (2,2)) == (2:3, 3:5)

@inferred global2blockindex(block_size, (3, 1)) == BlockIndex((2,1), (2,1))
@inferred global2blockindex(block_size, (1, 4)) == BlockIndex((1,2), (1,2))
@inferred global2blockindex(block_size, (4, 5)) == BlockIndex((3,2), (1,3))

@inferred blockindex2global(block_size, BlockIndex((2,1), (2,1))) == (3, 1)
@inferred blockindex2global(block_size, BlockIndex((1,2), (1,2))) == (1, 4)
@inferred blockindex2global(block_size, BlockIndex((3,2), (1,3))) == (4, 5)


@test block_size == BlockSizes(1:3, 2:3)

buf = IOBuffer()
print(buf, block_size)
@test String(take!(buf)) == "[1, 2, 3] × [2, 3]"

end
