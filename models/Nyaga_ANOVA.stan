data{
    int N;
    int Nt;
    int Ns;

    array[N] int TP;
    array[N] int Dis;
    array[N] int TN;
    array[N] int NDis;
    array[N] int Study;
    array[N] int Test;

}
parameters{
    matrix[2, Nt] logitmu;
    array[2] vector[Ns] nu;
    array[2] matrix[Ns, Nt] delta;
    array[2] vector<lower=0>[Nt] tau;
    vector<lower=0>[2] sigmab;
    real<lower=-1, upper=1> rho;
}

transformed parameters{
    array[Nt] matrix[Ns, 2] p_i;
    matrix[2, Nt] MU;
    array[2] matrix[Nt,Nt] RD;
    vector[Nt] DOR;
    vector[Nt] S;
    matrix[Nt, Nt] A;
    matrix[Nt, Nt] B;
    matrix[Nt, Nt] C;

    array[2] vector<lower=0>[Nt] tausq;
    vector<lower=0>[2] sigmabsq;

    array[2] matrix[Nt, Nt] sigmasq;
    array[2] matrix[Nt, Nt] rhow;


    for (i in 1:Ns){
        for (j in 1:2){
            for (k in 1:Nt)
                p_i[k][i,j] = inv_logit(logitmu[j,k] +  nu[j][i] + delta[j][i,k]);
        }
    }
 
    for (j in 1:2){
        for (k in 1:Nt){
            MU[j,k] = mean(col(p_i[k], j));
        }
        tausq[j] = (tau[j]).*(tau[j]);
    }

for (j in 1:2){
        for (k in 1:Nt){
            for (l in 1:Nt){
                RD[j][k,l] = MU[j, k]/MU[j, l];
              }
        }
    }



    for (l in 1:Nt){
        DOR[l] = (MU[1, l]*MU[2, l])/((1 - MU[1, l])*(1 - MU[2, l]));

        for(m in 1:Nt){
            A[l, m] = ((MU[1, l] > MU[1, m]) && (MU[2, l] > MU[2, m]))? 1 : 0;
            B[l, m] = ((MU[1, l] < MU[1, m]) && (MU[2, l] < MU[2, m]))? 1 : 0;
            C[l, m] = ((MU[1, l] == MU[1, m]) && (MU[2, l] == MU[2, m]))? 1 : 0;
        }

        S[l] = (2*sum(row(A, l)) + sum(row(C, l)))/(2*sum(row(B, l)) + sum(row(C, l)));
    }
    
    sigmabsq = (sigmab).*(sigmab);

    for (j in 1:2){
        for (k in 1:Nt){
            for (l in 1:Nt){
                sigmasq[j][k,l] = (sigmabsq[j] + tausq[j][k])*((sigmabsq[j] + tausq[j][l]));
                rhow[j][k,l] = sigmabsq[j]/sqrt(sigmasq[j][k,l]);
            }
        }
    }

}
model{
	//Priors
    for (j in 1:2){
        logitmu[j] ~ normal(0, 5);
		tau[j] ~ cauchy(0, 2.5);
    }

    sigmab ~ cauchy(0, 2.5);
	rho ~ uniform(-1, 1);

    nu[2] ~ normal(0, sigmab[2]);

    
    for (i in 1:Ns){

        nu[1][i] ~ normal((sigmab[1]/sigmab[2])*rho*nu[2][i], sqrt(sigmabsq[1]*(1 - (rho*rho))));

        for (j in 1:2){
            for (k in 1:Nt)
                delta[j][i,k] ~ normal(0, tau[j][k]);
        }
    }

    for (n in 1:N){
        TP[n] ~ binomial(Dis[n], p_i[Test[n]][Study[n], 1]);
        TN[n] ~ binomial(NDis[n], p_i[Test[n]][Study[n], 2]);
    }

}
generated quantities{
    vector[2*N] loglik;

    for (n in 1:N)
        loglik[n] = binomial_lpmf(TN[n]| NDis[n], p_i[Test[n]][Study[n], 1]);

    for (n in (N+1):(2*N))
        loglik[n] = binomial_lpmf(TN[n-N]| NDis[n-N], p_i[Test[n-N]][Study[n-N], 2]);

}

