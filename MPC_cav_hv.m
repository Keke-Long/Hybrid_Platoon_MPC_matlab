clear all
clc
tic
%% Step0: ��������
L= 5;     % ��������
d0 = 5;   % ��С��ȫ���
h = 0.6;  % ������ʱ��
tao = 0.4;% ��еʱ��
ts = 0.1; % ���沽��
Np = 6;  % Ԥ�ⲽ������Ҫ��ε��ԣ���˽�Ŀ����Ժͼ���Ч��
Nc = 5;  % ���Ʋ�������Ҫ��ε��ԣ���˽�Ŀ����Ժͼ���Ч��
Nx = 5;   % ״̬����Ŀ
Ny = 5;   % �������Ŀ
Nu = 1;   % ��������Ŀ
T = 2.2;    % T in IDM model ��IDM�ȶ�ʱ��headway 
%% Step1: ǰ���켣����
t = 0:ts:40;          % ����ʱ����
n = size(t,2);  
n = 1;
ref = zeros(n,5);
a_preceding = zeros(1,n); % ǰ�����ٶ�
v_preceding = zeros(1,n); % ǰ���ٶ�
x_preceding = zeros(1,n); % ǰ��λ��
for i = 1:n
    if t(i)<=20
        a_preceding(i) = 1;
        v_preceding(i) = a_preceding(i)*t(i);
    elseif t(i)>20 && t(i)<=30
        v_preceding(i) = 20;
    elseif t(i)>30 && t(i)<=40
        a_preceding(i) = -1.5;
        v_preceding(i) = 20+a_preceding(i)*(t(i)-30);
    end
    if i == 1
        x_preceding(i) = 0;
    else
        x_preceding(i) = x_preceding(i-1) + v_preceding(i)*ts + 0.5*a_preceding(i)*ts^2;
    end
end
ref(:,3) = [a_preceding]';
%% Step2:  ϵͳ״̬����
% ��1������ϵͳ״̬����: Dx = A*x+B1*u+B2*w; C = C*x+D*u
A = ts*[0,1,-h,0,0;
        0,0,-1,0,0;
        0,0,-1/tao,0,0;
        0,0,0,0,1;
        0,0,1,0,0]+diag([1,1,1,1,1]);
B1 = ts*[0,0,1/tao,0,0]';
B2 = ts*[0,0;
         1,0;
         0,0;
         0,-T;
         0,-1];
C = diag([1,1,1,1,1]); 
r = 0.1;              % ��������Ȩ��
q = diag([10,8,3,10,1]); % �������Ȩ��
% ��2����ɢϵͳ״̬����: x(k+1) = Ax*(k)+B1*u(k)+B2*w(k)
% ������Ϳ�������Ȩ�ؾ���
Q_cell = cell(Np,Np);
for i = 1:Np
    for j = 1:Np
        if i==j
            Q_cell{i,j} = q;
        else
            Q_cell{i,j} = zeros(Nx,Nx);
        end
    end
end
Q = cell2mat(Q_cell);
R = r*eye(Nc);
% ��ɢ״̬����ϵ������
Mx_cell = cell(Np,1);
Mu_cell = cell(Np,1);
Mw_cell = cell(Np,1);
for i = 1:Np
    Mx_cell{i,1} = C*A^(i);
    Mu_cell{i,1} = zeros(size(C*B1));
    Mw_cell{i,1} = zeros(size(C*B2));
    for j = 1:i
        Mu_cell{i,1}= Mu_cell{i,1}+C*A^(j-1)*B1;
        Mw_cell{i,1}= Mw_cell{i,1}+C*A^(j-1)*B2;
    end
end
Mx = cell2mat(Mx_cell);
Mu = cell2mat(Mu_cell);
Mw = cell2mat(Mw_cell);
Mdu_cell = cell(Np,Nc);
for i = 1:Np
    for j = 1:Nc
        Mdu_cell{i,j} = zeros(size(C*B1));
        if j<=i
            for k = j:i
                Mdu_cell{i,j} = Mdu_cell{i,j}+C*A^(i-k)*B1;
            end
        end
    end
end
Mdu = cell2mat(Mdu_cell);
%%  Step4: ��ͨԼ������
% ��1��������Լ��
u_min = -4.5;
u_max = 2.5;
U_min = kron(ones(Nc,1),u_min);
U_max = kron(ones(Nc,1),u_max);
% ��2����������Լ��
du_min = -3;
du_max = 3;
delta_Umin = kron(ones(Nc,1),du_min);
delta_Umax = kron(ones(Nc,1),du_max);
Row = 3;               % �ɳ�ϵ��
M = 10;                % �ɳڱ����Ͻ�
lb = [delta_Umin;0];   %����ⷽ�̣�״̬���½磬��������ʱ���ڿ����������ɳ�����
ub = [delta_Umax;M];   %����ⷽ�̣�״̬���Ͻ磬��������ʱ���ڿ����������ɳ�����
% ��3�����״̬Լ��
es_min = -1;
es_max = 3;
ev_min = -2;
ev_max = 2;
a_min = -4.5;
a_max = 2.5;
v_min = 0;
v_max = 40;
y_min = [es_min,ev_min,a_min,es_min,ev_min]';
y_max = [es_max,ev_max,a_max,es_max,ev_max]';
Y_min = kron(ones(Np,1),y_min);
Y_max = kron(ones(Np,1),y_max);
%%  Step5: �ɳ�Լ������
% (1) �������ɳ�Լ��
vdu_min = 0;
vdu_max = 0;
Vdu_min = kron(ones(Nc,1),vdu_min);
Vdu_max = kron(ones(Nc,1),vdu_max);
% (2) ���������ɳ�Լ��
vu_min = -0.01;
vu_max = 0.01;
Vu_min = kron(ones(Nc,1),vu_min);
Vu_max = kron(ones(Nc,1),vu_max);
% (3) ���״̬�ɳ�Լ��
vy_min = [0,-1,-0.1,0,-1]';
vy_max = [1, 1, 0.1,1, 1]';
VY_min = kron(ones(Np,1),vy_min);
VY_max = kron(ones(Np,1),vy_max);
%%  Step6: ��ʼֵ���ú�Ԥ����
X = zeros(n+1,5);
U = zeros(n+1,1);
X(1,:) = [0,0,0,0,0];
U(1,:) = 0;
A_I = kron(tril(ones(Nc,Nc)),eye(Nu));
PSI = kron(ones(Nc,1),eye(Nu));

a_2_list = zeros(n,1);
%%  Step7: MPC��Ҫ���
s0 = 2;
for k = 1:n
    k
    vi = v_preceding(k)-X(k,2)-X(k,5);
    delta_v = -X(k,5);
    delta_d = X(k,4) +s0+ vi*T;
    a_2 = IDM(vi, delta_v, delta_d);
    a_2_list(k) = a_2;

    w = [a_preceding(k),a_2]';
    
    H_cell = cell(2,2);
    H_cell{1,1} = 2*(Mdu'*Q*Mdu+R);
    H_cell{1,2} = zeros(Nu*Nc,1);
    H_cell{2,1} = zeros(1,Nu*Nc);
    H_cell{2,2} = Row;
    H = cell2mat(H_cell);
    H = (H+H')/2;

    E = kron(ones(Np,1),ref(k,:)')-Mx*X(k,:)'-Mu*U(k,:)'-Mw*w;
    f = [-2*(Mdu'*Q*E);0]';
    
    A_cons_cell = {A_I -Vu_max;
        -A_I Vu_min;
        Mdu -VY_max;
        -Mdu VY_min};
    b_cons_cell = {U_max-PSI*U(k,:)';
        -U_min+PSI*U(k,:)';
        Y_max-Mx*X(k,:)'-Mu*U(k,:)'-Mw*w;
        -Y_min+Mx*X(k,:)'+Mu*U(k,:)'+Mw*w};
    
    % ��1�����ι滮���
    A_cons = cell2mat(A_cons_cell);  %����ⷽ�̣�״̬������ʽԼ���������ת��Ϊ����ֵ��ȡֵ��Χ
    b_cons = cell2mat(b_cons_cell);  %����ⷽ�̣�״̬������ʽԼ����ȡֵ
    
    lb = [delta_Umin;0];             %����ⷽ�̣�״̬���½磬��������ʱ���ڿ����������ɳ�����
    ub = [delta_Umax;M];             %����ⷽ�̣�״̬���Ͻ磬��������ʱ���ڿ����������ɳ�����
    [du,fval,exitflag] = quadprog(H,f,A_cons,b_cons,[],[],lb,ub);
    % ��2�����¿�����
    U(k+1,:) = (U(k,:)'+du(1:Nu))';
    % ��3������״̬��
    X(k+1,:) = (A*X(k,:)'+B1*U(k+1,:)'+B2*w)';

end
%%  Step7: ������

v_cav = v_preceding-X(1:n,2)';
v_hv  = v_preceding-X(1:n,2)'-X(1:n,5)';
x_cav = x_preceding - X(1:n,1)' - L - h*v_cav;
x_hv  = x_cav - X(1:n,4)' - L - T*v_hv;

figure(1);
subplot(3,1,1);
plot(t,a_preceding, t,X(1:n,3), t,a_2_list);
ylim([-2 2.5]);
lgd=legend('preceding','CAV','HV');
lgd.Location = 'eastoutside';
xlabel('����ʱ��T');
ylabel('���ٶ�a');
hold off
grid on

subplot(3,1,2);
plot(t,v_preceding, t,v_cav, t, v_hv);
lgd=legend('preceding','CAV','HV');
lgd.Location = 'eastoutside';
xlabel('����ʱ��T');
ylabel('�ٶ�v');
hold off
grid on

subplot(3,1,3);
plot(t,x_preceding, t,x_cav, t,x_hv );
lgd=legend('preceding','CAV','HV');
lgd.Location = 'eastoutside';
xlabel('����ʱ��T');
ylabel('λ��x');
hold off
grid on

filename = ['MPC_cav_hv_Np' num2str(Np) '_Nc' num2str(Nc) '.png']; % �����ļ����ַ���
print(gcf, filename, '-dpng', '-r300');

toc