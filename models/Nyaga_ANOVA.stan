data{
    int N;
    int Nt;
    int Ns;

    int TP[N];
    int Dis[N];
    int TN[N];
    int NDis[N];
    int Study[N];
    int Test[N];

}
parameters{
    matrix[2, Nt] logitmu;
    vector[Ns] nu[2];
    matrix[Ns, Nt] delta[2];
    vector<lower=0>[Nt] tau[2]; //*
    vector<lower=0>[2] sigmab; 
    real<lower=-1, upper=1> rho;
}

transformed parameters{
    matrix[Ns, 2] p_i[Nt];
    matrix[2, Nt] MU;
    matrix[Nt,Nt] RD[2];
    vector[Nt] DOR;
    vector[Nt] S;
    matrix[Nt, Nt] A;
    matrix[Nt, Nt] B;
    matrix[Nt, Nt] C;

    vector<lower=0>[Nt] tausq[2];
    vector<lower=0>[2] sigmabsq;

    matrix[Nt, Nt] sigmasq[2];
    matrix[Nt, Nt] rhow[2];


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

