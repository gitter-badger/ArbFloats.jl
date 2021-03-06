
for (op,cop) in ((:(==), :(arb_eq)), (:(!=), :(arb_ne)),
                 (:(<=), :(arb_le)), (:(>=), :(arb_ge)),
                 (:(<), :(arb_lt)),  (:(>), :(arb_gt))  )
  @eval begin
    function ($op){T<:ArbFloat}(a::T, b::T)
        return Bool(ccall(@libarb($cop), Cint, (Ptr{T}, Ptr{T}), &a, &b) )
    end
    ($op){P,Q}(a::ArbFloat{P}, b::ArbFloat{Q}) = ($op)(promote(a,b)...)
    ($op){T<:ArbFloat,R<:Real}(a::T, b::R) = ($op)(promote(a,b)...)
    ($op){T<:ArbFloat,R<:Real}(a::R, b::T) = ($op)(promote(a,b)...)
  end
end


# for sorted ordering
isequal{T<:ArbFloat}(a::T, b::T) = !(a != b)
isless{T<:ArbFloat}(a::T, b::T) = !(a >= b)


# experimental  ≗
(≖){T<:ArbFloat}(x::T, y::T) = !(x != y)
(≖){P,Q}(x::ArbFloat{P}, y::ArbFloat{Q}) = (≖)(promote(x,y)...)
(≖){T1<:ArbFloat,T2<:Real}(x::T1, y::T2) = (≖)(promote(x,y)...)
(≖){T1<:ArbFloat,T2<:Real}(x::T2, y::T1) = (≖)(promote(x,y)...)

