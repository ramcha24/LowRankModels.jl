using LowRankModels
import StatsBase: sample, WeightVec

# tests MNL loss

srand(1);
m,n,k,kfit = 1000,500,3,4;
K = 2; # number of categories
d = n*K;
# matrix to encode
X_real, Y_real = randn(m,k), randn(k,d);
XY = X_real*Y_real;
A = zeros(Int, (m, n))
for i=1:m
	for j=1:n
		wv = WeightVec(Float64[exp(-XY[i, K*(j-1) + l]) for l in 1:K])
		l = sample(wv)
		A[i,j] = l
	end
end

# and the model
losses = fill(MultinomialLoss(K),n)
rx, ry = QuadReg(), QuadReg();
glrm = GLRM(A,losses,rx,ry,kfit, scale=false, offset=false, X=randn(kfit,m), Y=randn(kfit,d));

# initialize
init_svd!(glrm)
XYh = glrm.X' * glrm.Y
println("After initialization with the svd, parameters differ from true parameters by $(vecnorm(XY - XYh)/prod(size(XY))) in RMSE")
A_imputed = impute(glrm)
println("After initialization with the svd, $(sum(A_imputed .!= A) / prod(size(A))*100)\% of imputed entries are wrong")
println("(Picking randomly, $((K-1)/K*100)\% of entries would be wrong.)")

p = Params(1, max_iter=10, convergence_tol=0.0000001, min_stepsize=0.001) 
@time X,Y,ch = fit!(glrm, params=p);
XYh = X'*Y;
@show ch.objective
println("After fitting, parameters differ from true parameters by $(vecnorm(XY - XYh)/prod(size(XY))) in RMSE")
A_imputed = impute(glrm)
println("After fitting, $(sum(A_imputed .!= A) / prod(size(A))*100)\% of imputed entries are wrong")
println("(Picking randomly, $((K-1)/K*100)\% of entries would be wrong.)")